import AppKit
import BudsCore
import BudsUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private var menuBar: MenuBarController?

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    let model = BudsViewModel.mock()
    menuBar = MenuBarController(model: model)
  }
}
