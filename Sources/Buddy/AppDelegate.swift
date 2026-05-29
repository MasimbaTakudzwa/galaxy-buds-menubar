import AppKit
import CoreBluetooth
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

  /// Base advertisement is ~26 bytes; the discoverable ("lid open") burst
  /// appends an extra block, pushing it past this threshold.
  private static let discoverableLengthThreshold = 30

  func applicationDidFinishLaunching(_ notification: Notification) {
    print("=== Buddy 0.1 — BLE detect + BT connect monitor (build \(Self.buildTag)) ===")
    NSApp.setActivationPolicy(.accessory)

    let model = BudsViewModel.mock()
    self.model = model
    menuBar = MenuBarController(model: model)

    startConnectionMonitor()
    startBLEDetection()
  }

  private static let buildTag = "connect-monitor-1"

  private func startConnectionMonitor() {
    connectionMonitor.onConnect = { [weak self] name in
      print("[BT] connected: \(name) → showing HUD")
      self?.model?.onSimulateCaseOpen?()
    }
    connectionMonitor.onDisconnect = { name in
      print("[BT] disconnected: \(name)")
    }
    connectionMonitor.start()
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
