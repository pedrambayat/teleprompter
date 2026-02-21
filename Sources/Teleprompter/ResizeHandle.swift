import AppKit
import SwiftUI

/// A drag handle anchored to the bottom-right corner of the overlay window.
/// Dragging it resizes the window while keeping the top-left corner fixed.
struct ResizeHandle: NSViewRepresentable {

    func makeNSView(context: Context) -> ResizeHandleNSView {
        ResizeHandleNSView()
    }

    func updateNSView(_ nsView: ResizeHandleNSView, context: Context) {}
}

// MARK: -

final class ResizeHandleNSView: NSView {

    private var startMouseLocation: NSPoint = .zero
    private var startWindowFrame: NSRect   = .zero

    override var acceptsFirstResponder: Bool { false }

    override func resetCursorRects() {
        // Bottom-right diagonal resize cursor
        if let cursor = NSCursor.resizeUpDown as NSCursor? {
            addCursorRect(bounds, cursor: cursor)
        }
    }

    override func mouseDown(with event: NSEvent) {
        guard let win = window else { return }
        startMouseLocation = NSEvent.mouseLocation   // screen coordinates
        startWindowFrame   = win.frame
    }

    override func mouseDragged(with event: NSEvent) {
        guard let win = window else { return }

        let current = NSEvent.mouseLocation
        let dx = current.x - startMouseLocation.x   // positive = dragging right
        let dy = current.y - startMouseLocation.y   // positive = dragging up (screen coords)

        let newWidth  = max(win.minSize.width,  startWindowFrame.width + dx)
        let newHeight = max(win.minSize.height, startWindowFrame.height - dy)
        //                                                     ↑ drag DOWN (−dy) → taller

        var newFrame      = startWindowFrame
        newFrame.size     = NSSize(width: newWidth, height: newHeight)
        newFrame.origin.y = startWindowFrame.maxY - newHeight   // keep top edge fixed

        win.setFrame(newFrame, display: true, animate: false)
    }
}
