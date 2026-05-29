import Foundation
import IOBluetooth

/// Watches classic Bluetooth connect/disconnect events for the paired buds.
///
/// This is the right "you opened the case and they reconnected" trigger for a
/// device that's paired to the Mac — and the `IOBluetoothDevice` it surfaces is
/// the same object we'll open the RFCOMM control channel on next.
public final class BTConnectionMonitor: NSObject {
  public var nameFilter = "buds"
  public var onConnect: ((String) -> Void)?
  public var onDisconnect: ((String) -> Void)?

  private var connectNotification: IOBluetoothUserNotification?
  private var disconnectNotifications: [IOBluetoothUserNotification] = []

  public func start() {
    connectNotification = IOBluetoothDevice.register(
      forConnectNotifications: self,
      selector: #selector(deviceConnected(_:device:))
    )

    // Watch already-connected buds for their *next* disconnect so we catch the
    // reconnect, but don't fire onConnect at launch.
    if let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
      for device in paired where device.isConnected() && matches(device) {
        registerDisconnect(for: device)
      }
    }
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
    onConnect?(device.name ?? "—")
    registerDisconnect(for: device)
  }

  @objc private func deviceDisconnected(
    _ notification: IOBluetoothUserNotification,
    device: IOBluetoothDevice
  ) {
    guard matches(device) else { return }
    onDisconnect?(device.name ?? "—")
  }
}
