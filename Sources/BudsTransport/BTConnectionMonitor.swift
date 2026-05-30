import Foundation
import IOBluetooth

/// One service record found via SDP — name, primary UUID, RFCOMM channel.
public struct DiscoveredService: Sendable {
  public let name: String?
  public let uuid: String?
  public let rfcommChannelID: Int?
}

/// Watches classic Bluetooth connect/disconnect events for the paired buds.
///
/// This is the right "you opened the case and they reconnected" trigger for a
/// device that's paired to the Mac — and the `IOBluetoothDevice` it surfaces is
/// the same object we'll open the RFCOMM control channel on next.
public final class BTConnectionMonitor: NSObject, IOBluetoothRFCOMMChannelDelegate {
  public var nameFilter = "buds"
  public var onConnect: ((String) -> Void)?
  public var onDisconnect: ((String) -> Void)?
  public var onServices: (([DiscoveredService]) -> Void)?
  public var onControlOpen: ((Int32) -> Void)?
  public var onControlData: ((Data) -> Void)?

  private var connectNotification: IOBluetoothUserNotification?
  private var disconnectNotifications: [IOBluetoothUserNotification] = []
  private var connectedDevice: IOBluetoothDevice?
  private var controlChannel: IOBluetoothRFCOMMChannel?

  public func start() {
    connectNotification = IOBluetoothDevice.register(
      forConnectNotifications: self,
      selector: #selector(deviceConnected(_:device:))
    )

    // Watch already-connected buds for their *next* disconnect so we catch the
    // reconnect, but don't fire onConnect at launch. Probe services now though.
    if let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
      for device in paired where device.isConnected() && matches(device) {
        connectedDevice = device
        registerDisconnect(for: device)
        probeServices(device)
      }
    }
  }

  /// Opens an RFCOMM channel on the connected buds and streams incoming bytes.
  public func openControlChannel(_ channelID: Int) {
    guard let device = connectedDevice else { onControlOpen?(-1); return }
    var channel: IOBluetoothRFCOMMChannel?
    let result = device.openRFCOMMChannelAsync(
      &channel,
      withChannelID: BluetoothRFCOMMChannelID(channelID),
      delegate: self
    )
    if result == kIOReturnSuccess {
      controlChannel = channel
    } else {
      onControlOpen?(result)
    }
  }

  // MARK: IOBluetoothRFCOMMChannelDelegate

  public func rfcommChannelOpenComplete(
    _ rfcommChannel: IOBluetoothRFCOMMChannel!, status error: IOReturn
  ) {
    onControlOpen?(error)
  }

  public func rfcommChannelData(
    _ rfcommChannel: IOBluetoothRFCOMMChannel!,
    data dataPointer: UnsafeMutableRawPointer!,
    length dataLength: Int
  ) {
    onControlData?(Data(bytes: dataPointer, count: dataLength))
  }

  public func rfcommChannelClosed(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
    controlChannel = nil
  }

  private var sdpRetries = 0

  private func probeServices(_ device: IOBluetoothDevice) {
    device.performSDPQuery(self)
  }

  @objc private func sdpQueryComplete(_ device: IOBluetoothDevice, status: IOReturn) {
    var services: [DiscoveredService] = []
    if let records = device.services as? [IOBluetoothSDPServiceRecord] {
      for record in records {
        var channel: BluetoothRFCOMMChannelID = 0
        let hasChannel = record.getRFCOMMChannelID(&channel) == kIOReturnSuccess
        services.append(
          DiscoveredService(
            name: record.getServiceName(),
            uuid: primaryUUID(of: record),
            rfcommChannelID: hasChannel ? Int(channel) : nil
          )
        )
      }
    }

    // The first query after launch often hits an empty cache — retry a few times.
    if services.isEmpty && sdpRetries < 4 {
      sdpRetries += 1
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
        self?.probeServices(device)
      }
      return
    }
    sdpRetries = 0
    onServices?(services)
  }

  private func primaryUUID(of record: IOBluetoothSDPServiceRecord) -> String? {
    // Attribute 0x0001 = ServiceClassIDList (a sequence of UUID elements).
    guard let element = record.getAttributeDataElement(0x0001) else { return nil }
    if let array = element.getArrayValue() as? [IOBluetoothSDPDataElement] {
      for item in array {
        if let uuid = item.getUUIDValue() {
          return uuid.description
        }
      }
    }
    return element.getUUIDValue()?.description
  }

  private func matches(_ device: IOBluetoothDevice) -> Bool {
    (device.name ?? "").range(of: nameFilter, options: .caseInsensitive) != nil
  }

  private func registerDisconnect(for device: IOBluetoothDevice) {
    if let note = device.register(
      forDisconnectNotification: self,
      selector: #selector(deviceDisconnected(_:device:))
    ) {
      disconnectNotifications.append(note)
    }
  }

  @objc private func deviceConnected(
    _ notification: IOBluetoothUserNotification,
    device: IOBluetoothDevice
  ) {
    guard matches(device) else { return }
    connectedDevice = device
    onConnect?(device.name ?? "—")
    registerDisconnect(for: device)
    probeServices(device)
  }

  @objc private func deviceDisconnected(
    _ notification: IOBluetoothUserNotification,
    device: IOBluetoothDevice
  ) {
    guard matches(device) else { return }
    onDisconnect?(device.name ?? "—")
  }
}
