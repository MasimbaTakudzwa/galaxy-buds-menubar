import Foundation
import BudsProtocol
#if canImport(IOBluetooth)
import IOBluetooth
#endif

/// Wraps an RFCOMM channel to a paired Galaxy Buds device.
///
/// Stub: real implementation will open `IOBluetoothRFCOMMChannel` against the
/// Buds' SDP service UUID once it has been confirmed via `PacketLogger.app`.
public actor RFCOMMChannel {
  private var isOpen = false

  public init() {}

  public func open() async throws {
    isOpen = true
  }

  public func close() async {
    isOpen = false
  }

  public func send(_ frame: BudsFrame) async throws {
    _ = BudsFrameCodec.encode(frame)
  }

  public func incomingFrames() -> AsyncStream<BudsFrame> {
    AsyncStream { _ in }
  }
}
