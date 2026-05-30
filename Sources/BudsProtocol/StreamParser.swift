import Foundation

/// A decoded Galaxy Buds message: message ID + payload (CRC stripped).
public struct BudsMessage: Sendable {
  public let id: UInt8
  public let payload: [UInt8]
}

/// Reassembles the RFCOMM byte stream into Galaxy Buds frames.
///
/// Frame: `FD | header(2, LE) | msgID(1) | payload | CRC16(2) | DD`
/// where `header & 0x03FF` = (msgID + payload + CRC) length. RFCOMM chunks
/// don't align to frame boundaries — one read can hold several frames or a
/// partial one — so bytes are buffered until whole frames are available.
public final class BudsStreamParser {
  public static let som: UInt8 = 0xFD
  public static let eom: UInt8 = 0xDD

  private var buffer: [UInt8] = []

  public init() {}

  public func feed(_ bytes: [UInt8]) -> [BudsMessage] {
    buffer.append(contentsOf: bytes)
    var messages: [BudsMessage] = []
    while let message = next() {
      messages.append(message)
    }
    return messages
  }

  private func next() -> BudsMessage? {
    // Resync: drop anything before a start-of-message byte.
    while let first = buffer.first, first != Self.som {
      buffer.removeFirst()
    }
    guard buffer.count >= 4 else { return nil }

    let header = UInt16(buffer[1]) | (UInt16(buffer[2]) << 8)
    let length = Int(header & 0x03FF)        // msgID + payload + CRC
    guard length >= 3 else {                  // malformed — skip this SOM
      buffer.removeFirst()
      return nil
    }

    let frameSize = length + 4                // SOM + header(2) + length + EOM
    guard buffer.count >= frameSize else { return nil }   // need more bytes

    guard buffer[frameSize - 1] == Self.eom else {        // bad EOM — resync
      buffer.removeFirst()
      return nil
    }

    let id = buffer[3]
    let payloadLength = length - 3            // minus msgID(1) + CRC(2)
    let payload = Array(buffer[4 ..< 4 + payloadLength])
    buffer.removeFirst(frameSize)
    return BudsMessage(id: id, payload: payload)
  }
}
