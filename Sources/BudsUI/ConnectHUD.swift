import SwiftUI
import BudsCore

/// The AirPods-style popup that springs in when the case opens.
public struct ConnectHUD: View {
  let device: BudsDevice
  @State private var appeared = false

  public init(device: BudsDevice) {
    self.device = device
  }

  public var body: some View {
    VStack(spacing: 16) {
      BudsModel3DView(interactive: true)
        .frame(width: 150, height: 120)

      Text(device.name)
        .font(.headline)

      BatteryCluster(device: device)
    }
    .padding(26)
    .frame(width: 300)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
    .overlay(
      RoundedRectangle(cornerRadius: 24)
        .stroke(Color.white.opacity(0.08), lineWidth: 1)
    )
    .shadow(color: .black.opacity(0.35), radius: 30, y: 12)
    .scaleEffect(appeared ? 1 : 0.85)
    .opacity(appeared ? 1 : 0)
    .onAppear {
      withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
        appeared = true
      }
    }
  }
}
