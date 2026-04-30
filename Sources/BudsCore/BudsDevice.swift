import Foundation

public enum BudsModel: String, Sendable, CaseIterable {
  case buds3FE
}

public enum ANCMode: String, Sendable, CaseIterable {
  case off
  case ambient
  case anc

  public func next() -> ANCMode {
    switch self {
    case .off: return .ambient
    case .ambient: return .anc
    case .anc: return .off
    }
  }
}

public enum EQPreset: String, Sendable, CaseIterable {
  case normal
  case bassBoost
  case soft
  case dynamic
  case clear
  case treble
}

public struct BudsDevice: Equatable, Sendable {
  public var model: BudsModel
  public var leftBattery: Int?
  public var rightBattery: Int?
  public var caseBattery: Int?
  public var ancMode: ANCMode
  public var equalizer: EQPreset
  public var isWornLeft: Bool
  public var isWornRight: Bool
  public var isCaseOpen: Bool

  public init(
    model: BudsModel = .buds3FE,
    leftBattery: Int? = nil,
    rightBattery: Int? = nil,
    caseBattery: Int? = nil,
    ancMode: ANCMode = .off,
    equalizer: EQPreset = .normal,
    isWornLeft: Bool = false,
    isWornRight: Bool = false,
    isCaseOpen: Bool = false
  ) {
    self.model = model
    self.leftBattery = leftBattery
    self.rightBattery = rightBattery
    self.caseBattery = caseBattery
    self.ancMode = ancMode
    self.equalizer = equalizer
    self.isWornLeft = isWornLeft
    self.isWornRight = isWornRight
    self.isCaseOpen = isCaseOpen
  }
}
