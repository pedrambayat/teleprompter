import AppKit

/// A borderless, resizable, always-on-top window excluded from every macOS
/// screen-capture framebuffer via `sharingType = .none`.
/// Zoom, Teams, Google Meet, OBS, and `CGWindowListCreateImage` never see it.
final class TeleprompterWindow: NSWindow {

    var keyHandler: ((NSEvent) -> Void)?
    var scrollHandler: ((CGPoint) -> Void)?

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            // .resizable enables the window to change size programmatically and
            // lets the OS handle resize-cursor rects near edges / our custom handle.
            styleMask: [.borderless, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )

        // ── The critical line ──────────────────────────────────────────────
        self.sharingType = .none          // excluded from every screen-capture API
        // ──────────────────────────────────────────────────────────────────

        self.level = .floating
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.isMovableByWindowBackground = true
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.isExcludedFromWindowsMenu = true

        self.minSize = NSSize(width: 300, height: 140)
        self.maxSize = NSSize(width: 1400, height: 900)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    // MARK: - Keyboard

    override func keyDown(with event: NSEvent) {
        if let handler = keyHandler {
            handler(event)
        } else {
            super.keyDown(with: event)
        }
    }

    // MARK: - Scroll wheel

    override func scrollWheel(with event: NSEvent) {
        let multiplier: CGFloat = event.hasPreciseScrollingDeltas ? 1.0 : 8.0
        scrollHandler?(CGPoint(
            x: event.scrollingDeltaX * multiplier,
            y: event.scrollingDeltaY * multiplier
        ))
    }
}
