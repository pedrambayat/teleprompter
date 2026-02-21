import SwiftUI
import Observation

@Observable
@MainActor
final class TeleprompterViewModel {

    // MARK: - Script content
    var rawText: String = ""
    var isLoaded: Bool = false
    var loadedFileName: String = ""

    // MARK: - Appearance
    var fontSize: Double = 32
    var textColor: Color = .white
    var backgroundOpacity: Double = 0.75

    // MARK: - Playback
    var isPlaying: Bool = false
    var scrollSpeed: Double = 50     // points per second

    // MARK: - Scroll state (driven by ScrollEngine + scroll wheel)
    var scrollOffset: Double = 0
    var contentHeight: Double = 0    // full rendered text height
    var viewportHeight: Double = 0   // visible area height

    // MARK: - UI state
    var isTeleprompterVisible: Bool = false

    // MARK: - Computed

    var maxScrollOffset: Double {
        max(0, contentHeight - viewportHeight)
    }

    // MARK: - Rich Markdown display

    /// Builds an `AttributedString` with visual heading hierarchy:
    /// H1 = 1.6×, H2 = 1.35×, H3 = 1.15×, H4+ = 1.05× the user's chosen font size.
    /// Body text carries inline **bold** / *italic* via Foundation's Markdown parser.
    /// Accessing `fontSize` makes this re-evaluated whenever font size changes.
    var displayAttributedText: AttributedString {
        guard !rawText.isEmpty else {
            return AttributedString("Open a script file to begin…")
        }
        return buildRichMarkdown(rawText, baseSize: fontSize)
    }

    private func buildRichMarkdown(_ text: String, baseSize: Double) -> AttributedString {
        var result = AttributedString()
        let lines = text.components(separatedBy: "\n")

        for (idx, line) in lines.enumerated() {
            let isLast = idx == lines.count - 1
            let suffix = isLast ? "" : "\n"

            if let (level, content) = headingComponents(of: line) {
                // Extra blank line before major headings (not at document start)
                if level <= 2 && idx > 0 {
                    result += AttributedString("\n")
                }
                let scale: Double = switch level {
                    case 1:    1.60
                    case 2:    1.35
                    case 3:    1.15
                    default:   1.05
                }
                var segment = inlineParsed(content + suffix)
                // Setting .font on the whole segment overrides Text's .font modifier
                // for heading lines while body lines continue to use the modifier.
                segment.font = Font.system(size: baseSize * scale, weight: .bold)
                result += segment

            } else if line.range(of: #"^[-*]{3,}\s*$"#, options: .regularExpression) != nil {
                // Horizontal rule → decorative separator rendered smaller
                var segment = AttributedString("────────────────────────────────\n")
                segment.font = Font.system(size: baseSize * 0.55)
                result += segment

            } else {
                // Body line — inline markdown handles **bold** and *italic*
                result += inlineParsed(line + suffix)
            }
        }
        return result
    }

    private func headingComponents(of line: String) -> (level: Int, content: String)? {
        guard let r = line.range(of: #"^(#{1,6})[ \t]+"#, options: .regularExpression) else {
            return nil
        }
        let level = line[r].prefix(while: { $0 == "#" }).count
        return (level, String(line[r.upperBound...]))
    }

    private func inlineParsed(_ text: String) -> AttributedString {
        let opts = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        return (try? AttributedString(markdown: text, options: opts)) ?? AttributedString(text)
    }

    // MARK: - Playback helpers

    func togglePlayback() { isPlaying ? pause() : play() }

    func play() {
        guard !rawText.isEmpty else { return }
        if scrollOffset >= maxScrollOffset && maxScrollOffset > 0 { scrollOffset = 0 }
        isPlaying = true
    }

    func pause() { isPlaying = false }

    func resetToTop() {
        isPlaying = false
        scrollOffset = 0
    }

    func clampScrollOffset() {
        scrollOffset = min(scrollOffset, maxScrollOffset)
    }

    // MARK: - Font size convenience (also used by keyboard shortcuts)

    func increaseFontSize() {
        fontSize = min(80, fontSize + 2)
        scheduleSave()
    }

    func decreaseFontSize() {
        fontSize = max(16, fontSize - 2)
        scheduleSave()
    }

    // MARK: - Persistence

    func loadSettings() {
        let s = TeleprompterSettings.load()
        fontSize          = s.fontSize
        backgroundOpacity = s.backgroundOpacity
        scrollSpeed       = s.scrollSpeed
        textColor = Color(
            red:     s.textColorRed,
            green:   s.textColorGreen,
            blue:    s.textColorBlue,
            opacity: s.textColorAlpha
        )
    }

    func saveSettings() {
        var s = TeleprompterSettings.load()   // preserve window frame fields
        s.fontSize          = fontSize
        s.backgroundOpacity = backgroundOpacity
        s.scrollSpeed       = scrollSpeed
        if let ns = NSColor(textColor).usingColorSpace(.deviceRGB) {
            s.textColorRed   = ns.redComponent
            s.textColorGreen = ns.greenComponent
            s.textColorBlue  = ns.blueComponent
            s.textColorAlpha = ns.alphaComponent
        }
        s.save()
    }

    // MARK: - Debounced save

    private var saveTask: Task<Void, Never>?

    func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled, let self else { return }
            self.saveSettings()
        }
    }

    func flushSave() {
        saveTask?.cancel()
        saveTask = nil
        saveSettings()
    }
}
