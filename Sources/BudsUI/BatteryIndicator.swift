import SwiftUI

public struct BatteryIndicator: View {
  public let label: String
  public let percent: Int?

  public init(label: String, percent: Int?) {
    self.label = label
    self.percent = percent
  }

  public var body: some View {
    HStack(spacing: 6) {
      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(percent.map { "\($0)%" } ?? "—")
        .font(.caption.monospacedDigit())
    }
  }
}
