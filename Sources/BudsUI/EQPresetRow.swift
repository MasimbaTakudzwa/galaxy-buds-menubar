import SwiftUI
import BudsCore

public struct EQPresetRow: View {
  let selection: EQPreset
  let onSelect: (EQPreset) -> Void

  public init(selection: EQPreset, onSelect: @escaping (EQPreset) -> Void) {
    self.selection = selection
    self.onSelect = onSelect
  }

  public var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(EQPreset.allCases, id: \.self) { preset in
          let active = preset == selection
          Button {
            onSelect(preset)
          } label: {
            Text(preset.displayName)
              .font(.callout)
              .padding(.horizontal, 14)
              .padding(.vertical, 7)
              .background(
                active ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary.opacity(0.6)),
                in: Capsule()
              )
              .foregroundStyle(active ? Color.white : Color.primary)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 2)
      .padding(.vertical, 1)
    }
  }
}
