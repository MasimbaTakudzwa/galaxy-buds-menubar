import Foundation
import CoreBluetooth

/// A single BLE advertisement seen during a scan.
public struct BudsAdvertisement: Sendable {
  public let identifier: UUID
  public let name: String?
  public let rssi: Int
  public let manufacturerID: UInt16?
  public let manufacturerData: Data

  public var manufacturerHex: String {
    manufacturerData.map { String(format: "%02x", $0) }.joined()
  }
}

/// Passive CoreBluetooth scanner.
///
/// Reconnaissance phase: it reports nearby advertisements (default-filtered to
/// Samsung, manufacturer ID 0x0075) so we can capture the Buds 3 FE payload and
/// reverse-engineer the battery/lid bytes. Requires a signed .app bundle with
/// NSBluetoothAlwaysUsageDescription — see Packaging/make-app.sh.
public final class AdvertScanner: NSObject, CBCentralManagerDelegate {
  /// Restrict reports to this manufacturer ID. Samsung = 0x0075. Set nil for all.
  public var manufacturerFilter: UInt16? = 0x0075
  public var onAdvertisement: ((BudsAdvertisement) -> Void)?
  public var onState: ((CBManagerState) -> Void)?

  private var central: CBCentralManager!

  public override init() {
    super.init()
    central = CBCentralManager(delegate: self, queue: nil)
  }

  public func start() {
    guard central.state == .poweredOn else { return }
    central.scanForPeripherals(
      withServices: nil,
      options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
    )
  }

  public func stop() {
    central.stopScan()
  }

  public func centralManagerDidUpdateState(_ central: CBCentralManager) {
    onState?(central.state)
    if central.state == .poweredOn { start() }
  }

  public func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi RSSI: NSNumber
  ) {
    guard
      let mfg = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
      mfg.count >= 2
    else { return }

    let id = UInt16(mfg[0]) | (UInt16(mfg[1]) << 8)
    if let filter = manufacturerFilter, id != filter { return }

    let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
      ?? peripheral.name

    onAdvertisement?(
      BudsAdvertisement(
        identifier: peripheral.identifier,
        name: name,
        rssi: RSSI.intValue,
        manufacturerID: id,
        manufacturerData: mfg
      )
    )
  }
}
