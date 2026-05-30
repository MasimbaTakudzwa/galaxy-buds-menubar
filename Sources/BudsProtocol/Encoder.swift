import Foundation

/// CRC-16/XMODEM (poly 0x1021, init 0x0000, no reflection).
///
/// Verified against live Galaxy Buds 3 FE frames: the CRC of (msgID + payload)
/// matches the trailing two bytes (stored little-endian) of every captured frame.
public enum CRC16 {
  public static func xmodem(_ data: [UInt8]) -> UInt16 {
    var crc: UInt16 = 0
    for byte in data {
      crc ^= UInt16(byte) << 8
      for _ in 0..<8 {
        crc = (crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : (crc << 1)
      }
    }
    return crc
  }
}

/// Builds a Galaxy Buds frame ready to write to the RFCOMM channel.
///
/// `FD | length(2, LE) | msgID | payload | CRC16-XMODEM(2, LE) | DD`
/// where `length = 1 (msgID) + payload + 2 (CRC)`.
public enum BudsMessageEncoder {
  public static func encode(id: UInt8, payload: [UInt8] = []) -> [UInt8] {
    var body: [UInt8] = [id]
    body.append(contentsOf: payload)
    let crc = CRC16.xmodem(body)
    let length = body.count + 2  // + CRC bytes

    var frame: [UInt8] = [BudsStreamParser.som]
    frame.append(UInt8(length & 0xFF))
    frame.append(UInt8((length >> 8) & 0xFF))
    frame.append(contentsOf: body)
    frame.append(UInt8(crc & 0xFF))         // CRC low byte first (little-endian)
    frame.append(UInt8((crc >> 8) & 0xFF))
    frame.append(BudsStreamParser.eom)
    return frame
  }

  /// Self-test: re-encode a known-good captured frame and compare byte-for-byte.
  /// Returns true if the encoder reproduces the real frame exactly.
  public static func selfTest() -> Bool {
    let id: UInt8 = 0x61
    let payload: [UInt8] = [
      0x00,0x0b,0x3c,0x00,0x00,0x01,0x10,0x00,0x00,0x00,0xff,0x22,0x02,0x00,0x5b,0x01,
      0x5b,0x01,0x00,0x00,0x04,0x99,0x00,0x04,0x04,0x10,0x00,0x01,0x00,0x00,0x00,0x00,
      0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
      0x01,0x02,0x00,0x00,0x00,0x00,0x01,0x01,0x00,0x00,0x00,0x00
    ]
    // Real captured frame (header has no flags set, so it's canonical).
    let expected: [UInt8] = [0xFD, 0x3F, 0x00] + [id] + payload + [0x46, 0x8D, 0xDD]
    return encode(id: id, payload: payload) == expected
  }
}
