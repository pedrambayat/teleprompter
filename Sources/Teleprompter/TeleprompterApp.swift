import SwiftUI

@main
struct TeleprompterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No visible windows — AppDelegate manages a status bar item and overlay window.
        // Settings scene is the minimal scene needed to satisfy the App protocol.
        Settings {
            EmptyView()
        }
    }
}
