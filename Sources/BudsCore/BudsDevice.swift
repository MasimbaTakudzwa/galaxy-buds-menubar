import Foundation

public enum BudsModel: String, Sendable, CaseIterable {
  case buds3FE
}

public enum ANCMode: String, Sendable, CaseIterable {
  case off
  case ambient
  case adaptive
  case anc

  public func next() -> ANCMode {
    switch self {
    case .off: return .ambient
    case .ambient: return .adaptive
    case .adaptive: return .anc
    case .anc: return .off
    }
  }

  public var displayName: String {
    switch self {
    case .off: "Off"
    case .ambient: "Ambient"
    case .adaptive: "Adaptive"
    case .anc: "ANC"
    }
  }

  /// SF Symbol used in the ANC control. Approximations — easy to swap.
  public var systemImage: String {
    switch self {
    case .off: "minus.circle.fill"
    case .ambient: "ear.fill"
    case .adaptive: "dot.radiowaves.left.and.right"
    case .anc: "waveform.slash"
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

  public var displayName: String {
    switch self {
    case .normal: "Normal"
    case .bassBoost: "Bass Boost"
    case .soft: "Soft"
    case .dynamic: "Dynamic"
    case .clear: "Clear"
    case .treble: "Treble"
    }
  }
}

public struct BudsDevice: Equatable, Sendable {
  public var model: BudsModel
  public var name: String
  public var leftBattery: Int?
  public var rightBattery: Int?
  public var caseBattery: Int?
  public var leftCharging: Bool
  public var rightCharging: Bool
  public var caseCharging: Bool
  public var ancMode: ANCMode
  public var availableANCModes: [ANCMode]
  public var equalizer: EQPreset
  public var isWornLeft: Bool
  public var isWornRight: Bool
  public var isCaseOpen: Bool

  public init(
    model: BudsModel = .buds3FE,
    name: String = "Galaxy Buds 3 FE",
    leftBattery: Int? = nil,
    rightBattery: Int? = nil,
    caseBattery: Int? = nil,
    leftCharging: Bool = false,
    rightCharging: Bool = false,
    caseCharging: Bool = false,
    ancMode: ANCMode = .off,
    availableANCModes: [ANCMode] = [.off, .ambient, .adaptive, .anc],
    equalizer: EQPreset = .normal,
    isWornLeft: Bool = false,
    isWornRight: Bool = false,
    isCaseOpen: Bool = false
  ) {
    self.model = model
    self.name = name
    self.leftBattery = leftBattery
    self.rightBattery = rightBattery
    self.caseBattery = caseBattery
    self.leftCharging = leftCharging
    self.rightCharging = rightCharging
    self.caseCharging = caseCharging
    self.ancMode = ancMode
    self.availableANCModes = availableANCModes
    self.equalizer = equalizer
    self.isWornLeft = isWornLeft
    self.isWornRight = isWornRight
    self.isCaseOpen = isCaseOpen
  }

  /// Fixture for UI work — no Bluetooth involved.
  /// `availableANCModes` is set to all four; the real Buds 3 FE may expose
  /// fewer (e.g. no Adaptive) — the control renders whatever is in this list.
  public static let mock = BudsDevice(
    name: "Galaxy Buds 3 FE",
    leftBattery: 92,
    rightBattery: 88,
    caseBattery: 62,
    leftCharging: true,
    rightCharging: true,
    caseCharging: false,
    ancMode: .off,
    equalizer: .normal
  )
}
