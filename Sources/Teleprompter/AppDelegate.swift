import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private(set) var windowController: TeleprompterWindowController!
    private(set) var viewModel: TeleprompterViewModel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)   // no Dock icon, no Cmd+Tab entry

        viewModel = TeleprompterViewModel()
        viewModel.loadSettings()

        windowController = TeleprompterWindowController(viewModel: viewModel)

        // ── Popover ────────────────────────────────────────────────────────
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 440)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: SettingsPanelView(viewModel: viewModel,
                                        windowController: windowController)
        )

        // ── Status bar item ────────────────────────────────────────────────
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.text.magnifyingglass",
                                   accessibilityDescription: "Teleprompter")
            // Receive both left- and right-click so we can differentiate them
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Flush any pending debounced save and persist the current window position.
        viewModel.flushSave()
        windowController.saveWindowFrame()
    }

    // MARK: - Status bar actions

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showQuitMenu()
        } else {
            togglePopover(sender)
        }
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        }
    }

    /// Shows a minimal right-click context menu with a Quit item.
    private func showQuitMenu() {
        let menu = NSMenu()
        menu.addItem(.init(title: "Quit Teleprompter",
                           action: #selector(NSApplication.terminate(_:)),
                           keyEquivalent: "q"))

        // Temporarily attach the menu so performClick triggers it, then remove it
        // so future left-clicks still open the popover.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // Clear on the next run-loop pass to restore normal left-click behaviour
        DispatchQueue.main.async { [weak self] in
            self?.statusItem.menu = nil
        }
    }
}
