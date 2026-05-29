import SwiftUI
import BudsCore

public struct BatteryRing: View {
  let label: String
  let percent: Int?
  let charging: Bool

  public init(label: String, percent: Int?, charging: Bool = false) {
    self.label = label
    self.percent = percent
    self.charging = charging
  }

  private var fraction: Double { Double(percent ?? 0) / 100 }

  private var tint: Color {
    guard let percent else { return .secondary }
    if percent <= 15 { return .red }
    if percent <= 30 { return .orange }
    return .green
  }

  public var body: some View {
    VStack(spacing: 7) {
      ZStack {
        Circle()
          .stroke(Color.primary.opacity(0.12), lineWidth: 5)
        Circle()
          .trim(from: 0, to: fraction)
          .stroke(tint.gradient, style: StrokeStyle(lineWidth: 5, lineCap: .round))
          .rotationEffect(.degrees(-90))
          .animation(.spring(response: 0.5, dampingFraction: 0.8), value: fraction)
        VStack(spacing: 1) {
          Text(percent.map { "\($0)" } ?? "–")
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .monospacedDigit()
          if charging {
            Image(systemName: "bolt.fill")
              .font(.system(size: 8))
              .foregroundStyle(.green)
          }
        }
      }
      .frame(width: 56, height: 56)

      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}

public struct BatteryCluster: View {
  let device: BudsDevice

  public init(device: BudsDevice) {
    self.device = device
  }

  public var body: some View {
    HStack(spacing: 22) {
      BatteryRing(label: "Left", percent: device.leftBattery, charging: device.leftCharging)
      BatteryRing(label: "Right", percent: device.rightBattery, charging: device.rightCharging)
      BatteryRing(label: "Case", percent: device.caseBattery, charging: device.caseCharging)
    }
  }
}
