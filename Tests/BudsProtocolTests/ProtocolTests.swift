import Foundation
import Testing
@testable import BudsProtocol

// MARK: CRC + encoder

@Test func crcCanonicalCheckValue() {
  // CRC-16/XMODEM check value for "123456789" is 0x31C3.
  #expect(CRC16.xmodem(Array("123456789".utf8)) == 0x31C3)
}

@Test func encoderReproducesCapturedFrame() {
  #expect(BudsMessageEncoder.selfTest())
}

@Test func encoderFraming() {
  let frame = BudsMessageEncoder.encode(id: 0x79, payload: [0x01])
  #expect(frame.first == 0xFD)
  #expect(frame.last == 0xDD)
  #expect(frame[1] == 0x04 && frame[2] == 0x00)   // length = msgID + payload + CRC
  #expect(frame[3] == 0x79 && frame[4] == 0x01)
  #expect(frame.count == 8)
}

// MARK: Stream parser

@Test func parseSingleFrame() {
  let frame = BudsMessageEncoder.encode(id: 0x42, payload: [1, 2, 3])
  let messages = BudsStreamParser().feed(frame)
  #expect(messages.count == 1)
  #expect(messages[0].id == 0x42)
  #expect(messages[0].payload == [1, 2, 3])
}

@Test func parseConcatenatedFrames() {
  let bytes = BudsMessageEncoder.encode(id: 0x10, payload: [0xAA])
    + BudsMessageEncoder.encode(id: 0x20, payload: [0xBB, 0xCC])
  let messages = BudsStreamParser().feed(bytes)
  #expect(messages.map(\.id) == [0x10, 0x20])
}

@Test func parserIgnoresHeaderFlagBits() {
  // Received frames set flag bits in the header high byte; length is the low 10 bits.
  var frame = BudsMessageEncoder.encode(id: 0x61, payload: [9, 9, 9])
  frame[2] |= 0x40
  let messages = BudsStreamParser().feed(frame)
  #expect(messages.count == 1 && messages[0].payload == [9, 9, 9])
}

@Test func parserReassemblesAcrossReads() {
  let frame = BudsMessageEncoder.encode(id: 0x42, payload: [1, 2, 3, 4])
  let parser = BudsStreamParser()
  #expect(parser.feed(Array(frame.prefix(4))).isEmpty)
  let messages = parser.feed(Array(frame.dropFirst(4)))
  #expect(messages.count == 1 && messages[0].id == 0x42)
}

@Test func parserResyncsOnGarbage() {
  let noisy = [UInt8(0x00), 0xFF, 0x12] + BudsMessageEncoder.encode(id: 0x10, payload: [0xAA])
  let messages = BudsStreamParser().feed(noisy)
  #expect(messages.count == 1 && messages[0].id == 0x10)
}

// MARK: Status decoder

@Test func decodeExtendedStatus() {
  let payload: [UInt8] = [0x00, 0x0b, 0x3c, 0x00, 0x00, 0x01, 0x10, 0x00]
    + Array(repeating: 0, count: 52)
  let status = BudsStatusDecoder.decode(BudsMessage(id: 0x61, payload: payload))
  #expect(status?.leftBattery == 60)    // p[2] = 0x3c
  #expect(status?.rightBattery == nil)  // p[3] = 0 → not reported
  #expect(status?.caseBattery == nil)   // p[7] = 0 → not reported
}

@Test func decodeStatusUpdated() {
  let payload: [UInt8] = [0x01, 0x64, 0x64, 0x01, 0x01, 0x11, 0x39, 0x00]
  let status = BudsStatusDecoder.decode(BudsMessage(id: 0x60, payload: payload))
  #expect(status?.leftBattery == 100)   // p[1]
  #expect(status?.rightBattery == 100)  // p[2]
  #expect(status?.caseBattery == 57)    // p[6] = 0x39
}

@Test func decoderIgnoresUnknownMessages() {
  #expect(BudsStatusDecoder.decode(BudsMessage(id: 0xf2, payload: [1, 2, 3])) == nil)
}
