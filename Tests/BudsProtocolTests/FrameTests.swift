import Foundation
import Testing
@testable import BudsProtocol

@Test func roundTrip() throws {
  let frame = BudsFrame(opcode: 0x60, payload: Data([0x01, 0x02, 0x03]))
  let encoded = BudsFrameCodec.encode(frame)
  let decoded = try BudsFrameCodec.decode(encoded)
  #expect(decoded == frame)
}

@Test func truncatedRejected() {
  #expect(throws: BudsFrameError.truncated) {
    try BudsFrameCodec.decode(Data([0xFE, 0xDC]))
  }
}

@Test func missingSOM() {
  #expect(throws: BudsFrameError.missingSOM) {
    try BudsFrameCodec.decode(Data([0x00, 0x60, 0xDC]))
  }
}
