import AppKit
import CoreBluetooth
import BudsProtocol
import BudsCore
import BudsTransport
import BudsUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private var menuBar: MenuBarController?
  private var model: BudsViewModel?
  private let scanner = AdvertScanner()
  private let connectionMonitor = BTConnectionMonitor()
  private var lastPayload: [UUID: String] = [:]
  private var discoverable: [UUID: Bool] = [:]
  private var didOpenControl = false
  private var channelOverride: Int?
  private var pendingSends: [[UInt8]] = []
  private let parser = BudsStreamParser()

  /// Base advertisement is ~26 bytes; the discoverable ("lid open") burst
  /// appends an extra block, pushing it past this threshold.
  private static let discoverableLengthThreshold = 30

  func applicationDidFinishLaunching(_ notification: Notification) {
    print("=== Buddy 0.1 — BLE detect + BT connect monitor (build \(Self.buildTag)) ===")
    if let idx = CommandLine.arguments.firstIndex(of: "--channel"),
       idx + 1 < CommandLine.arguments.count,
       let n = Int(CommandLine.arguments[idx + 1]) {
      channelOverride = n
      print("[RFCOMM] channel override = \(n)")
    }
    print("[SELFTEST] encoder = \(BudsMessageEncoder.selfTest() ? "PASS" : "FAIL")")
    parseSendArgs()
    NSApp.setActivationPolicy(.accessory)

    let model = BudsViewModel.mock()
    self.model = model
    model.onControl = { [weak self] request in self?.sendControl(request) }
    menuBar = MenuBarController(model: model)

    startConnectionMonitor()
    startBLEDetection()
  }

  // MARK: Sending

  /// Parse `--send AABBCC` args (first byte = msgID, rest = payload) into queued frames.
  private func parseSendArgs() {
    let args = CommandLine.arguments
    var i = 0
    while i < args.count {
      if args[i] == "--send", i + 1 < args.count,
         let bytes = Self.hexBytes(args[i + 1]), let id = bytes.first {
        pendingSends.append(BudsCommand.raw(id: id, payload: Array(bytes.dropFirst())))
        print("[SEND] queued id=\(String(format: "0x%02x", id)) payload=\(bytes.dropFirst().map { String(format: "%02x", $0) }.joined(separator: " "))")
        i += 2
      } else {
        i += 1
      }
    }
  }

  private func flushPendingSends() {
    for (n, frame) in pendingSends.enumerated() {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 * Double(n + 1)) { [weak self] in
        self?.connectionMonitor.send(frame)
      }
    }
  }

  private func sendControl(_ request: BudsControlRequest) {
    let frame: [UInt8]
    switch request {
    case .setANC(let mode): frame = BudsCommand.noiseControl(value: Self.ancWireValue(mode))
    case .setEQ(let preset): frame = BudsCommand.equalizer(preset: Self.eqWireValue(preset))
    }
    connectionMonitor.send(frame)
  }

  // CANDIDATE wire mappings — verify on hardware.
  private static func ancWireValue(_ mode: ANCMode) -> UInt8 {
    switch mode { case .off: 0; case .anc: 1; case .ambient: 2; case .adaptive: 3 }
  }
  private static func eqWireValue(_ preset: EQPreset) -> UInt8 {
    switch preset {
    case .normal: 0; case .bassBoost: 1; case .soft: 2
    case .dynamic: 3; case .clear: 4; case .treble: 5
    }
  }

  private static func hexBytes(_ string: String) -> [UInt8]? {
    let clean = string.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: ":", with: "")
    guard clean.count % 2 == 0 else { return nil }
    var out: [UInt8] = []
    var idx = clean.startIndex
    while idx < clean.endIndex {
      let next = clean.index(idx, offsetBy: 2)
      guard let byte = UInt8(clean[idx..<next], radix: 16) else { return nil }
      out.append(byte)
      idx = next
    }
    return out
  }

  private static let buildTag = "send-path-11"

  private func startConnectionMonitor() {
    connectionMonitor.onConnect = { [weak self] name in
      print("[BT] connected: \(name) → showing HUD")
      self?.model?.onSimulateCaseOpen?()
    }
    connectionMonitor.onDisconnect = { name in
      print("[BT] disconnected: \(name)")
    }
    connectionMonitor.onServices = { [weak self] services in
      print("[SDP] \(services.count) service(s):")
      for service in services {
        let channel = service.rfcommChannelID.map { "RFCOMM ch \($0)" } ?? "no-rfcomm"
        print("[SDP]   • \(service.name ?? "(unnamed)")  uuid=\(service.uuid ?? "?")  [\(channel)]")
      }
      self?.openControlChannel(from: services)
    }
    connectionMonitor.onControlOpen = { [weak self] status in
      print("[RFCOMM] open complete: status=\(status) \(status == 0 ? "(OK — listening)" : "(error)")")
      if status == 0 { self?.flushPendingSends() }
    }
    connectionMonitor.onWrite = { bytes, status in
      let hex = bytes.map { String(format: "%02x", $0) }.joined(separator: " ")
      print("[SEND] -> \(bytes.count)B (status=\(status)): \(hex)")
    }
    connectionMonitor.onControlData = { [weak self] data in
      // IOBluetooth delivers on a background thread; hop to main before we
      // touch the parser state or the SwiftUI model.
      DispatchQueue.main.async {
        guard let self else { return }
        for message in self.parser.feed([UInt8](data)) {
          self.log(message)
        }
      }
    }
    connectionMonitor.start()
  }

  private func openControlChannel(from services: [DiscoveredService]) {
    guard !didOpenControl else { return }
    // Match GEARMANAGER by its stable UUID (the SDP name field is sometimes empty).
    let channel = channelOverride
      ?? services.first(where: { ($0.uuid ?? "").lowercased().contains("2e73a4ad") })?.rfcommChannelID
      ?? services.first(where: { $0.name == "GEARMANAGER" })?.rfcommChannelID
    guard let channel else {
      print("[RFCOMM] GEARMANAGER not found — pass --channel 27 to force it")
      return
    }
    didOpenControl = true
    print("[RFCOMM] opening channel \(channel)…")
    connectionMonitor.openControlChannel(channel)
  }

  private func log(_ message: BudsMessage) {
    let idHex = String(format: "0x%02x", message.id)

    // Surface small unknown messages (ANC/control are small; debug spam is large)
    // so we can spot the noise-control message when ANC changes.
    guard message.id == 0x60 || message.id == 0x61 else {
      if message.payload.count <= 8 {
        let hex = message.payload.map { String(format: "%02x", $0) }.joined(separator: " ")
        print("[MSG?] id=\(idHex) len=\(message.payload.count)  payload= \(hex)")
      }
      return
    }

    let hex = message.payload.map { String(format: "%02x", $0) }.joined(separator: " ")
    print("[MSG] id=\(idHex) len=\(message.payload.count)  payload= \(hex)")
    let candidates = message.payload.enumerated()
      .filter { (1...100).contains($0.element) }
      .map { "p[\($0.offset)]=\($0.element)" }
      .joined(separator: " ")
    print("[MSG]   candidates(1–100): \(candidates)")

    guard let status = BudsStatusDecoder.decode(message) else { return }
    func fmt(_ value: Int?) -> String { value.map(String.init) ?? "–" }
    print("[BATTERY] left=\(fmt(status.leftBattery)) right=\(fmt(status.rightBattery)) case=\(fmt(status.caseBattery))")
    model?.apply(status)
  }

  private func startBLEDetection() {
    scanner.onState = { state in
      print("[BLE] state = \(Self.describe(state))")
    }
    scanner.onAdvertisement = { [weak self] ad in
      self?.handle(ad)
    }
  }

  private func handle(_ ad: BudsAdvertisement) {
    // Log payload changes (recon aid).
    if lastPayload[ad.identifier] != ad.manufacturerHex {
      let tag = lastPayload[ad.identifier] == nil ? "NEW    " : "CHANGED"
      lastPayload[ad.identifier] = ad.manufacturerHex
      print("[BLE] \(tag)  \(ad.name ?? "—")  rssi=\(ad.rssi)  data=\(ad.manufacturerHex)")
    }

    // Detection: a buds-named device transitioning into its discoverable
    // (lid-open) form fires the Connect HUD.
    guard ad.name?.range(of: "buds", options: .caseInsensitive) != nil else { return }
    let isDiscoverable = ad.manufacturerData.count > Self.discoverableLengthThreshold
    let wasDiscoverable = discoverable[ad.identifier] ?? false
    discoverable[ad.identifier] = isDiscoverable

    if isDiscoverable && !wasDiscoverable {
      print("[BLE] lid-open detected for \(ad.name ?? "—") → showing HUD")
      model?.onSimulateCaseOpen?()
    }
  }

  private static func describe(_ state: CBManagerState) -> String {
    switch state {
    case .poweredOn: "poweredOn — scanning"
    case .poweredOff: "poweredOff"
    case .unauthorized: "unauthorized — grant Bluetooth in System Settings > Privacy"
    case .unsupported: "unsupported"
    case .resetting: "resetting"
    case .unknown: "unknown"
    @unknown default: "unknown(\(state.rawValue))"
    }
  }
}
