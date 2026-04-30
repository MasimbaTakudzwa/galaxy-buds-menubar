import Foundation
import BudsProtocol
import BudsTransport

public actor BudsManager {
  public private(set) var device: BudsDevice?
  private let channel = RFCOMMChannel()
  private var stateContinuation: AsyncStream<BudsDevice?>.Continuation?

  public init() {}

  public lazy var state: AsyncStream<BudsDevice?> = {
    AsyncStream { continuation in
      self.stateContinuation = continuation
    }
  }()

  public func connect() async throws {
    try await channel.open()
  }

  public func disconnect() async {
    await channel.close()
    device = nil
    stateContinuation?.yield(nil)
  }
}
