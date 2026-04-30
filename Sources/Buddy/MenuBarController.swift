import AppKit
import BudsCore

@MainActor
final class MenuBarController {
  private let statusItem: NSStatusItem
  private let manager = BudsManager()

  init() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.button?.image = NSImage(
      systemSymbolName: "earbuds",
      accessibilityDescription: "Buddy"
    )
    statusItem.menu = buildMenu()
  }

  private func buildMenu() -> NSMenu {
    let menu = NSMenu()

    let header = NSMenuItem(title: "Buddy", action: nil, keyEquivalent: "")
    header.isEnabled = false
    menu.addItem(header)

    menu.addItem(.separator())

    let status = NSMenuItem(title: "No buds connected", action: nil, keyEquivalent: "")
    status.isEnabled = false
    menu.addItem(status)

    menu.addItem(.separator())

    menu.addItem(
      withTitle: "Quit Buddy",
      action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q"
    )

    return menu
  }
}
