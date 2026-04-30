import Foundation
import BudsCore

public struct ANCController: Sendable {
  public init() {}

  public func cycle(from current: ANCMode) -> ANCMode {
    current.next()
  }
}
