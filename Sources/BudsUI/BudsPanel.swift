import AppKit
import SwiftUI
import BudsCore

/// Main menubar panel — Samsung's information architecture, AirPods' motion.
public struct BudsPanel: View {
  @ObservedObject var model: BudsViewModel

  public init(model: BudsViewModel) {
    self.model = model
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      header

      BatteryCluster(device: model.device)
        .frame(maxWidth: .infinity)

      section("Noise control") {
        ANCSegmentedControl(
          modes: model.device.availableANCModes,
          selection: model.device.ancMode,
          onSelect: model.selectANC
        )
      }

      section("Equalizer") {
        EQPresetRow(selection: model.device.equalizer, onSelect: model.selectEQ)
      }

      settingsList

      footer
    }
    .padding(18)
    .frame(width: 340)
    .background(.regularMaterial)
  }

  private var header: some View {
    HStack(spacing: 12) {
      BudsModel3DView()
        .frame(width: 46, height: 46)
      VStack(alignment: .leading, spacing: 2) {
        Text(model.device.name)
          .font(.headline)
        Text(model.isConnected ? "Connected" : "Not connected")
          .font(.caption)
          .foregroundStyle(model.isConnected ? .green : .secondary)
      }
      Spacer()
    }
  }

  private func section<Content: View>(
    _ title: String,
    @ViewBuilder _ content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title.uppercased())
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
      content()
    }
  }

  private var settingsList: some View {
    VStack(spacing: 0) {
      settingsRow("Sound quality and effects", "slider.horizontal.3")
      Divider().padding(.leading, 46)
      settingsRow("Earbud controls", "hand.tap.fill")
      Divider().padding(.leading, 46)
      settingsRow("Voice controls", "mic.fill")
      Divider().padding(.leading, 46)
      settingsRow("Manage connections", "arrow.triangle.2.circlepath")
    }
    .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
  }

  private func settingsRow(_ title: String, _ icon: String) -> some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .frame(width: 22)
        .foregroundStyle(.secondary)
      Text(title)
        .font(.body)
      Spacer()
      Image(systemName: "chevron.right")
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .contentShape(Rectangle())
  }

  private var footer: some View {
    HStack(spacing: 10) {
      Button {
        model.onSimulateCaseOpen?()
      } label: {
        Label("Simulate case open", systemImage: "bolt.circle.fill")
          .font(.callout)
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .tint(.green)
      .controlSize(.large)

      Button {
        NSApplication.shared.terminate(nil)
      } label: {
        Image(systemName: "power")
          .font(.callout)
          .frame(width: 30)
      }
      .buttonStyle(.bordered)
      .controlSize(.large)
      .help("Quit Buddy")
    }
  }
}
