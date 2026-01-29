import SwiftUI

@main
struct ScreenFixerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
        } label: {
            Image(systemName: "display.2")
        }
        .menuBarExtraStyle(.window)
    }
}

/// App delegate for handling application lifecycle
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let displayNotifier = DisplayChangeNotifier.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register for display change notifications
        displayNotifier.register()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Unregister from display change notifications
        displayNotifier.unregister()
    }
}
