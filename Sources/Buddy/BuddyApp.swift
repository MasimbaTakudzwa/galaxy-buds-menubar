import SwiftUI

@main
struct BuddyApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    Settings {
      SettingsView()
    }
  }
}

struct SettingsView: View {
  var body: some View {
    Text("Buddy settings — coming soon")
      .frame(width: 480, height: 320)
  }
}
