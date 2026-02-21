# Teleprompter

A native macOS teleprompter that runs as a floating overlay **completely invisible to Zoom, Teams, Google Meet, OBS, and every other screen-sharing tool**.

## Features

- **Screen-capture invisible** — `NSWindow.sharingType = .none` keeps the overlay off every shared screen
- **Menu-bar only** — no Dock icon, no Cmd+Tab entry; lives quietly in the menu bar
- **Rich Markdown rendering** — headings scale visually (H1 = 1.6×, H2 = 1.35×…), bold and italic rendered inline
- **Smooth auto-scroll** — 60 Hz, time-delta based (constant speed regardless of frame drops)
- **Manual scroll** — trackpad or mouse wheel with per-device sensitivity
- **On-window controls** — hover to reveal: play/pause, reset, speed slider, font ±, close
- **Resizable** — drag the bottom-right corner handle to any size
- **Draggable** — click and drag anywhere on the background to reposition
- **Keyboard shortcuts** (click the overlay to focus it first):

  | Key | Action |
  |-----|--------|
  | `Space` | Play / Pause |
  | `R` | Reset to top |
  | `Esc` | Pause |
  | `+` | Increase font size |
  | `−` | Decrease font size |

- **Persistent settings** — font size, colour, opacity, scroll speed, window position and size survive restarts
- **No dependencies** — zero third-party packages; pure Swift + AppKit + SwiftUI

---

## Requirements

| | |
|--|--|
| **macOS** | 14.0 Sonoma or later |
| **Xcode** | 15.0+ (for Xcode builds) |
| **Swift** | 5.9+ (included with Xcode 15 or Command Line Tools) |

---

## Installation

### Option A — Build from source (no Xcode required)

```bash
git clone https://github.com/pedrambayat/teleprompter.git
cd teleprompter
./build.sh
open Teleprompter.app
```

The script compiles a release binary, assembles a `.app` bundle, and ad-hoc signs it.

### Option B — Xcode project via XcodeGen

```bash
brew install xcodegen
xcodegen generate
open Teleprompter.xcodeproj
```

Then build and run with **Cmd+R**.

### Option C — Manual Xcode project

1. Xcode → File → New → Project → macOS → App
2. Name: `Teleprompter`, Interface: SwiftUI, Language: Swift
3. Deployment target: macOS 14.0
4. Replace the generated Swift files with everything in `Sources/Teleprompter/`
5. Copy `AppResources/Info.plist` entries into the target's Info tab
6. Set `AppResources/Teleprompter.entitlements` as the entitlements file
7. Build & Run

---

## Usage

1. **Click the menu bar icon** (document + magnifier) to open the settings panel.
2. **Open a script file** — `.txt` or `.md` formats supported. The overlay appears automatically.
3. **Drag the overlay** to position it on screen (click anywhere on the background).
4. **Resize** by dragging the bottom-right corner handle.
5. **Hover over the overlay** to reveal controls:
   - *Top strip:* × (close), A− / A+ (font size)
   - *Bottom strip:* ⏮ (reset), ▶/⏸ (play/pause), speed slider
6. **Click the overlay** to give it keyboard focus, then use `Space` / `R` / `Esc` / `+` / `−`.
7. **Right-click the menu bar icon** to quit the app.

### Supported Markdown

| Syntax | Renders as |
|--------|-----------|
| `# Heading 1` | Large bold text (1.6× font size) |
| `## Heading 2` | Bold text (1.35×) |
| `### Heading 3` | Bold text (1.15×) |
| `**bold**` | Bold |
| `*italic*` | Italic |
| `---` | Horizontal rule separator |

---

## Project structure

```
teleprompter/
├── Package.swift                          # Swift Package Manager manifest
├── build.sh                               # Build + bundle + sign script
├── project.yml                            # XcodeGen spec
├── AppResources/
│   ├── Info.plist                         # LSUIElement = YES
│   └── Teleprompter.entitlements          # App Sandbox, user-selected files
└── Sources/Teleprompter/
    ├── TeleprompterApp.swift              # @main — SwiftUI App entry point
    ├── AppDelegate.swift                  # Menu bar item, popover, window setup
    ├── TeleprompterWindow.swift           # NSWindow subclass — sharingType = .none
    ├── TeleprompterWindowController.swift # Window lifecycle, keyboard, resize
    ├── TeleprompterViewModel.swift        # @Observable source of truth
    ├── TeleprompterSettings.swift         # Codable UserDefaults persistence
    ├── ScrollEngine.swift                 # 60 Hz timer-based auto-scroll
    ├── FileLoader.swift                   # Security-scoped .txt / .md reading
    ├── ResizeHandle.swift                 # Drag-to-resize corner NSViewRepresentable
    ├── TeleprompterView.swift             # Overlay: text + chrome + controls
    ├── ControlStripView.swift             # Play/pause/speed — shown on hover
    └── SettingsPanelView.swift            # Popover: file, appearance, speed
```

---

## Screen-sharing verification

1. Start a Zoom screen share (share your full screen).
2. Look at Zoom's green "sharing" preview — the teleprompter window is absent.
3. Ask a meeting participant to confirm — they cannot see it.

The same is true for Teams, Google Meet, OBS Studio, QuickTime screen recording, and `screencapture` CLI.

---

## Contributing

Pull requests are welcome!

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes
4. Open a pull request

---

## License

MIT — see [LICENSE](LICENSE).
