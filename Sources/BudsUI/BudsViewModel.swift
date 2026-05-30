import SwiftUI
import BudsCore
import BudsProtocol

@MainActor
public final class BudsViewModel: ObservableObject {
  @Published public var device: BudsDevice
  @Published public var isConnected: Bool

  /// Wired by the app to pop the Connect HUD (NSPanel) during the mock.
  public var onSimulateCaseOpen: (() -> Void)?

  public init(device: BudsDevice, isConnected: Bool = true) {
    self.device = device
    self.isConnected = isConnected
  }

  public static func mock() -> BudsViewModel {
    BudsViewModel(device: .mock)
  }

  public func selectANC(_ mode: ANCMode) {
    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
      device.ancMode = mode
    }
  }

  public func selectEQ(_ preset: EQPreset) {
    withAnimation(.easeOut(duration: 0.2)) {
      device.equalizer = preset
    }
  }

  /// Push a decoded status frame from the buds into the UI.
  public func apply(_ status: BudsStatus) {
    isConnected = true
    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
      if let left = status.leftBattery { device.leftBattery = left }
      if let right = status.rightBattery { device.rightBattery = right }
      device.caseBattery = status.caseBattery   // nil until we pin the offset
      // Charging state isn't decoded yet — clear the mock bolts.
      device.leftCharging = false
      device.rightCharging = false
      device.caseCharging = false
    }
  }
}
