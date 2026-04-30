import Foundation

/// Samsung MGR-style protocol frame.
///
/// Layout placeholder — verify against captured Buds 3 FE traffic before relying on it:
///   SOM (1) | type/size (3) | opcode (1) | payload (n) | CRC16 (2) | EOM (1)
public struct BudsFrame: Equatable, Sendable {
  public let opcode: UInt8
  public let payload: Data

  public init(opcode: UInt8, payload: Data = Data()) {
    self.opcode = opcode
    self.payload = payload
  }
}

public enum BudsFrameError: Error, Equatable {
  case missingSOM
  case missingEOM
  case truncated
  case crcMismatch
}

public enum BudsFrameCodec {
  public static let som: UInt8 = 0xFE
  public static let eom: UInt8 = 0xDC

  public static func encode(_ frame: BudsFrame) -> Data {
    var out = Data()
    out.append(som)
    out.append(frame.opcode)
    out.append(frame.payload)
    out.append(eom)
    return out
  }

  public static func decode(_ data: Data) throws -> BudsFrame {
    guard data.count >= 3 else { throw BudsFrameError.truncated }
    guard data.first == som else { throw BudsFrameError.missingSOM }
    guard data.last == eom else { throw BudsFrameError.missingEOM }
    let opcode = data[data.index(after: data.startIndex)]
    let payload = data.dropFirst(2).dropLast()
    return BudsFrame(opcode: opcode, payload: Data(payload))
  }
}
