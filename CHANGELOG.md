# Changelog

All notable changes to Teleprompter are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.0.0] — 2026-02-21

### Added
- Floating overlay window invisible to all screen-capture tools (Zoom, Teams,
  Google Meet, OBS) via `NSWindow.sharingType = .none`
- Menu-bar-only app (`LSUIElement = YES`) — no Dock icon
- Open `.txt` and `.md` script files via file picker or drag-and-drop
- Rich Markdown rendering: H1–H4 headings scale from 1.6× to 1.05× the base
  font size; `**bold**` and `*italic*` inline formatting; `---` horizontal rules
- 60 Hz time-delta–based auto-scroll (constant speed regardless of frame drops)
- Manual scroll via trackpad / mouse wheel with trackpad vs. mouse-wheel
  sensitivity differentiation
- On-overlay control strip (hover to reveal): play/pause, reset to top,
  speed slider
- On-overlay window chrome (hover to reveal): close button, A− / A+ font
  size controls
- Resizable window via drag handle at bottom-right corner
- Keyboard shortcuts (overlay must be focused): Space = play/pause, R = reset,
  Esc = pause, + = increase font size, − = decrease font size
- Right-click the menu bar icon → "Quit Teleprompter"
- Settings popover: font size, background opacity, text colour, scroll speed
- Scroll progress bar always visible at the bottom of the overlay
- "End of Script" banner when auto-scroll reaches the end
- Persistent settings (font, colour, opacity, speed, window position & size)
  saved to `UserDefaults` with 500 ms debounce
- Ad-hoc code signing in `build.sh`; sandbox entitlement applied
- macOS 14.0 (Sonoma) minimum deployment target
