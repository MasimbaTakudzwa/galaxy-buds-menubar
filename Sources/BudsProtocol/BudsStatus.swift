import Foundation

/// Decoded battery / wear state from a status message.
public struct BudsStatus: Sendable {
  public var leftBattery: Int?
  public var rightBattery: Int?
  public var caseBattery: Int?
  public var placement: UInt8?
}

public enum BudsStatusDecoder {
  /// Decode the two battery-bearing messages, whose layouts differ by one byte.
  ///
  /// Offsets verified for Galaxy Buds 3 FE from live captures (values tracked
  /// real battery drift; case byte appeared only while docked):
  ///   0x61 EXTENDED_STATUS_UPDATED: p[2]=left p[3]=right p[6]=placement p[7]=case
  ///   0x60 STATUS_UPDATED:          p[1]=left p[2]=right p[5]=placement p[6]=case
  /// A battery byte of 0 means "not reported" (e.g. case while buds are out).
  public static func decode(_ message: BudsMessage) -> BudsStatus? {
    let p = message.payload
    switch message.id {
    case 0x61 where p.count > 7:
      return BudsStatus(
        leftBattery: validBattery(p[2]),
        rightBattery: validBattery(p[3]),
        caseBattery: validBattery(p[7]),
        placement: p[6]
      )
    case 0x60 where p.count > 6:
      return BudsStatus(
        leftBattery: validBattery(p[1]),
        rightBattery: validBattery(p[2]),
        caseBattery: validBattery(p[6]),
        placement: p[5]
      )
    default:
      return nil
    }
  }

  private static func validBattery(_ byte: UInt8) -> Int? {
    (1...100).contains(byte) ? Int(byte) : nil
  }
}
