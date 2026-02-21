import AppKit
import SwiftUI

@MainActor
final class TeleprompterWindowController: NSWindowController, NSWindowDelegate {

    let viewModel: TeleprompterViewModel
    private var resizeSaveTask: Task<Void, Never>?

    init(viewModel: TeleprompterViewModel) {
        self.viewModel = viewModel

        let screen = NSScreen.main ?? NSScreen.screens[0]
        let sw = screen.visibleFrame.width
        let sh = screen.visibleFrame.height
        let ww: CGFloat = 620
        let wh: CGFloat = 280
        let defaultRect = NSRect(
            x: screen.visibleFrame.minX + (sw - ww) / 2,
            y: screen.visibleFrame.minY + sh * 0.62,
            width: ww,
            height: wh
        )

        let window = TeleprompterWindow(contentRect: defaultRect)
        super.init(window: window)

        window.delegate = self   // receive windowDidResize / windowDidEndLiveResize

        window.contentView = NSHostingView(
            rootView: TeleprompterView(viewModel: viewModel,
                                       onClose: { /* set below after super.init */ })
        )

        // Re-assign root view now that self is fully initialised so the closure
        // can capture self weakly without compiler complaints.
        window.contentView = NSHostingView(
            rootView: TeleprompterView(viewModel: viewModel,
                                       onClose: { [weak self] in self?.hide() })
        )

        setupHandlers(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Visibility

    func show() {
        restoreWindowFrame()
        window?.orderFrontRegardless()
        viewModel.isTeleprompterVisible = true
    }

    func hide() {
        saveWindowFrame()
        window?.orderOut(nil)
        viewModel.isTeleprompterVisible = false
    }

    func toggle() {
        viewModel.isTeleprompterVisible ? hide() : show()
    }

    // MARK: - Window frame persistence

    func saveWindowFrame() {
        guard let frame = window?.frame else { return }
        var s = TeleprompterSettings.load()
        s.windowX             = frame.origin.x
        s.windowY             = frame.origin.y
        s.windowWidth         = frame.size.width
        s.windowHeight        = frame.size.height
        s.windowPositionSaved = true
        s.save()
    }

    private func restoreWindowFrame() {
        let s = TeleprompterSettings.load()
        guard s.windowPositionSaved else { return }
        let frame = NSRect(x: s.windowX, y: s.windowY,
                           width: s.windowWidth, height: s.windowHeight)
        let onScreen = NSScreen.screens.contains { $0.frame.intersects(frame) }
        if onScreen { window?.setFrame(frame, display: false) }
    }

    // MARK: - NSWindowDelegate — save frame after live resize ends

    func windowDidEndLiveResize(_ notification: Notification) {
        saveWindowFrame()
    }

    // Also debounce-save for programmatic resizes from the custom handle
    func windowDidResize(_ notification: Notification) {
        resizeSaveTask?.cancel()
        resizeSaveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            self?.saveWindowFrame()
        }
    }

    // MARK: - Input handlers

    private func setupHandlers(window: TeleprompterWindow) {
        window.keyHandler = { [weak self] event in
            guard let self else { return }
            switch event.keyCode {
            case 49:  self.viewModel.togglePlayback()    // Space
            case 15:  self.viewModel.resetToTop()        // R
            case 53:  self.viewModel.pause()             // Escape
            case 24:  self.viewModel.increaseFontSize()  // + / =
            case 27:  self.viewModel.decreaseFontSize()  // −
            default:  break
            }
        }

        window.scrollHandler = { [weak self] delta in
            guard let vm = self?.viewModel else { return }
            vm.isPlaying = false
            let newOffset = vm.scrollOffset - delta.y
            vm.scrollOffset = max(0, min(vm.maxScrollOffset, newOffset))
        }
    }
}
