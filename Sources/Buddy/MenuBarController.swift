import AppKit
import SwiftUI
import BudsCore
import BudsUI

@MainActor
final class MenuBarController {
  private let statusItem: NSStatusItem
  private let popover = NSPopover()
  private let model: BudsViewModel
  private let hud: HUDController

  init(model: BudsViewModel) {
    self.model = model
    self.hud = HUDController(model: model)

    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    if let image = NSImage(systemSymbolName: "earbuds", accessibilityDescription: "Buddy") {
      statusItem.button?.image = image
    } else {
      statusItem.button?.title = "Buddy"
    }
    statusItem.button?.action = #selector(togglePopover)
    statusItem.button?.target = self

    let hosting = NSHostingController(rootView: BudsPanel(model: model))
    hosting.sizingOptions = .preferredContentSize
    popover.behavior = .transient
    popover.contentViewController = hosting

    model.onSimulateCaseOpen = { [weak self] in
      self?.popover.performClose(nil)
      self?.hud.show()
    }
  }

  @objc private func togglePopover() {
    guard let button = statusItem.button else { return }
    if popover.isShown {
      popover.performClose(nil)
    } else {
      popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
      popover.contentViewController?.view.window?.makeKey()
    }
  }
}
