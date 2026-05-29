import AppKit
import SwiftUI
import BudsCore
import BudsUI

/// Hosts the Connect HUD in a borderless floating panel and auto-dismisses it.
@MainActor
final class HUDController {
  private let model: BudsViewModel
  private var panel: NSPanel?
  private var dismissTask: Task<Void, Never>?
  private var lastShown = Date.distantPast

  init(model: BudsViewModel) {
    self.model = model
  }

  func show() {
    // Debounce: a connect event and a BLE burst can arrive together.
    guard Date().timeIntervalSince(lastShown) > 1.5 else { return }
    lastShown = Date()

    dismissTask?.cancel()

    let panel = panel ?? makePanel()
    self.panel = panel

    // Fresh hosting view each time so ConnectHUD.onAppear replays the spring.
    let hosting = NSHostingView(rootView: ConnectHUD(device: model.device).padding(10))
    hosting.frame.size = hosting.fittingSize
    panel.setContentSize(hosting.fittingSize)
    panel.contentView = hosting

    positionTopCenter(panel)
    panel.orderFrontRegardless()

    dismissTask = Task { [weak self] in
      try? await Task.sleep(for: .seconds(4))
      guard !Task.isCancelled else { return }
      self?.panel?.orderOut(nil)
    }
  }

  private func makePanel() -> NSPanel {
    let panel = NSPanel(
      contentRect: NSRect(x: 0, y: 0, width: 320, height: 260),
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    panel.isFloatingPanel = true
    panel.level = .statusBar
    panel.backgroundColor = .clear
    panel.isOpaque = false
    panel.hasShadow = false
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    return panel
  }

  private func positionTopCenter(_ panel: NSPanel) {
    guard let screen = NSScreen.main else { return }
    let area = screen.visibleFrame
    let size = panel.frame.size
    let x = area.midX - size.width / 2
    let y = area.maxY - size.height - 24
    panel.setFrameOrigin(NSPoint(x: x, y: y))
  }
}
