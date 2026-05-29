import SwiftUI
import BudsCore

public struct ANCSegmentedControl: View {
  let modes: [ANCMode]
  let selection: ANCMode
  let onSelect: (ANCMode) -> Void

  @Namespace private var pillNamespace

  public init(modes: [ANCMode], selection: ANCMode, onSelect: @escaping (ANCMode) -> Void) {
    self.modes = modes
    self.selection = selection
    self.onSelect = onSelect
  }

  public var body: some View {
    HStack(spacing: 4) {
      ForEach(modes, id: \.self) { mode in
        let active = mode == selection
        Button {
          onSelect(mode)
        } label: {
          VStack(spacing: 6) {
            ZStack {
              if active {
                Circle()
                  .fill(Color.accentColor)
                  .matchedGeometryEffect(id: "pill", in: pillNamespace)
                  .frame(width: 42, height: 42)
              }
              Image(systemName: mode.systemImage)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(active ? Color.white : Color.primary)
                .frame(width: 42, height: 42)
            }
            Text(mode.displayName)
              .font(.caption2)
              .foregroundStyle(active ? Color.primary : Color.secondary)
          }
          .frame(maxWidth: .infinity)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
    .padding(8)
    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
  }
}
