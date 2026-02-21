import SwiftUI
import UniformTypeIdentifiers

/// Settings popover attached to the status bar icon.
/// Left-click the icon to open. Right-click for Quit.
struct SettingsPanelView: View {

    @Bindable var viewModel: TeleprompterViewModel
    let windowController: TeleprompterWindowController

    @State private var isFileImporterShown = false
    @State private var errorMessage: String?

    private static let allowedTypes: [UTType] = {
        var t: [UTType] = [.plainText]
        if let md = UTType(filenameExtension: "md") { t.append(md) }
        return t
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ─────────────────────────────────────────────────────
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title2)
                    .accessibilityHidden(true)
                Text("Teleprompter")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // ── Script ─────────────────────────────────────────────
                    section("Script") {
                        Button { isFileImporterShown = true } label: {
                            Label("Open File…", systemImage: "folder")
                                .frame(maxWidth: .infinity)
                        }
                        .controlSize(.large)

                        if viewModel.isLoaded {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.text").foregroundStyle(.secondary)
                                Text(viewModel.loadedFileName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                    }

                    // ── Overlay ────────────────────────────────────────────
                    section("Overlay") {
                        Button { windowController.toggle() } label: {
                            Label(
                                viewModel.isTeleprompterVisible ? "Hide Overlay" : "Show Overlay",
                                systemImage: viewModel.isTeleprompterVisible ? "eye.slash" : "eye"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .controlSize(.large)
                        .tint(viewModel.isTeleprompterVisible ? .orange : .accentColor)
                    }

                    // ── Appearance ─────────────────────────────────────────
                    section("Appearance") {
                        LabeledSlider(
                            label: "Font Size",
                            value: $viewModel.fontSize,
                            range: 16...80,
                            format: "%.0f pt"
                        )
                        LabeledSlider(
                            label: "Background",
                            value: $viewModel.backgroundOpacity,
                            range: 0...1,
                            format: "%.0f%%",
                            displayMultiplier: 100
                        )
                        HStack {
                            Text("Text Color").font(.subheadline)
                            Spacer()
                            ColorPicker("Text Color", selection: $viewModel.textColor)
                                .labelsHidden()
                                .accessibilityLabel("Text color")
                        }
                    }

                    // ── Speed ──────────────────────────────────────────────
                    section("Scroll Speed") {
                        LabeledSlider(
                            label: "Speed",
                            value: $viewModel.scrollSpeed,
                            range: 10...250,
                            format: "%.0f px/s"
                        )
                    }

                    // ── Keyboard reference ─────────────────────────────────
                    section("Keyboard Shortcuts") {
                        Text("Click the overlay to give it focus, then:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            shortcutRow("Space",   "Play / Pause")
                            shortcutRow("R",       "Reset to top")
                            shortcutRow("Esc",     "Pause")
                            shortcutRow("+ / −",   "Font size ±2 pt")
                        }
                    }

                    Divider()

                    // ── Quit ───────────────────────────────────────────────
                    Button(role: .destructive) {
                        NSApp.terminate(nil)
                    } label: {
                        Label("Quit Teleprompter", systemImage: "power")
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
        }
        .frame(width: 320)

        // ── File importer ──────────────────────────────────────────────────
        .fileImporter(
            isPresented: $isFileImporterShown,
            allowedContentTypes: Self.allowedTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                if let err = FileLoader.load(url: url, into: viewModel) {
                    errorMessage = err   // route to alert — never into rawText
                } else if !viewModel.isTeleprompterVisible {
                    windowController.show()
                }
            case .failure(let err):
                errorMessage = err.localizedDescription
            }
        }

        // ── Error alert (file picker AND file-read errors) ─────────────────
        .alert("Could Not Open File",
               isPresented: Binding(
                    get:  { errorMessage != nil },
                    set:  { if !$0 { errorMessage = nil } }
               )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            if let msg = errorMessage { Text(msg) }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundStyle(.secondary)
                .fontWeight(.semibold)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    @ViewBuilder
    private func shortcutRow(_ key: String, _ description: String) -> some View {
        HStack(spacing: 8) {
            Text(key)
                .font(.caption.monospaced())
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color(NSColor.controlColor))
                .cornerRadius(4)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - LabeledSlider

private struct LabeledSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String
    var displayMultiplier: Double = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.subheadline)
                Spacer()
                Text(String(format: format, value * displayMultiplier))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range)
                .accessibilityLabel(label)
                .accessibilityValue(String(format: format, value * displayMultiplier))
        }
    }
}
