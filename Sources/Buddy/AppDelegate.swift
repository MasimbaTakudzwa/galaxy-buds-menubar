import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
  private var menuBar: MenuBarController?

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    menuBar = MenuBarController()
  }
}
