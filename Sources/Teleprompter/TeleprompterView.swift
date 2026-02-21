import SwiftUI

struct TeleprompterView: View {

    @Bindable var viewModel: TeleprompterViewModel
    var onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var scrollEngine: ScrollEngine?
    @State private var isHovering: Bool = false
    @State private var hideTask: Task<Void, Never>?
    @State private var showEndBanner: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {

                // ── Background ─────────────────────────────────────────────
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(viewModel.backgroundOpacity))

                // ── Scrolling text ─────────────────────────────────────────
                textContent(containerWidth: geo.size.width)
                    .frame(width: geo.size.width, height: geo.size.height,
                           alignment: .topLeading)
                    .clipped()

                // ── Progress bar (always visible) ──────────────────────────
                progressBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                    .accessibilityLabel("Scroll progress")
                    .accessibilityValue(progressAccessibilityValue)

                // ── Window chrome strip (hover, top) ───────────────────────
                VStack {
                    if isHovering {
                        windowChrome
                            .transition(reduceMotion ? .identity : .opacity)
                    }
                    Spacer()
                }

                // ── Playback control strip (hover, bottom) ─────────────────
                if isHovering {
                    ControlStripView(viewModel: viewModel)
                        .padding(.bottom, 20)
                        .transition(reduceMotion ? .identity : .opacity)
                }

                // ── End-of-script banner ───────────────────────────────────
                if showEndBanner {
                    Text("End of Script")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(.ultraThinMaterial)
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
                        .clipShape(Capsule())
                        .padding(.bottom, 58)
                        .transition(reduceMotion ? .identity
                                                 : .scale(scale: 0.9).combined(with: .opacity))
                        .accessibilityLabel("End of script reached")
                }

                // ── Resize handle (bottom-right corner) ────────────────────
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        ResizeHandle()
                            .frame(width: 22, height: 22)
                            .opacity(isHovering ? 0.5 : 0.2)
                            .overlay(
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .rotationEffect(.degrees(90))
                                    .allowsHitTesting(false)
                            )
                            .accessibilityLabel("Resize window")
                    }
                }
                .padding(6)
            }
            .onAppear { viewModel.viewportHeight = geo.size.height }
            .onChange(of: geo.size.height) { _, h in
                viewModel.viewportHeight = h
                viewModel.clampScrollOffset()
            }
        }
        // Hover with 0.5 s hide delay
        .onHover { entering in
            if entering {
                hideTask?.cancel()
                hideTask = nil
                animate { isHovering = true }
            } else {
                hideTask = Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    guard !Task.isCancelled else { return }
                    animate { isHovering = false }
                }
            }
        }
        // Scroll engine lifecycle
        .onChange(of: viewModel.isPlaying) { _, playing in
            if playing {
                let engine = ScrollEngine(viewModel: viewModel)
                scrollEngine = engine
                engine.start()
            } else {
                scrollEngine?.stop()
                scrollEngine = nil
                checkForNaturalEnd()
            }
        }
        // Keep scrollOffset in bounds when content height changes
        .onChange(of: viewModel.contentHeight) { _, _ in viewModel.clampScrollOffset() }
        // Debounced appearance saves
        .onChange(of: viewModel.fontSize)          { _, _ in viewModel.scheduleSave() }
        .onChange(of: viewModel.backgroundOpacity) { _, _ in viewModel.scheduleSave() }
        .onChange(of: viewModel.scrollSpeed)       { _, _ in viewModel.scheduleSave() }
        .onChange(of: viewModel.textColor)         { _, _ in viewModel.scheduleSave() }
    }

    // MARK: - Window chrome (top strip)

    private var windowChrome: some View {
        HStack {
            // Close / hide overlay
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.75))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Hide overlay")
            .accessibilityLabel("Hide overlay")

            Spacer()

            // Font size controls
            HStack(spacing: 14) {
                Button {
                    viewModel.decreaseFontSize()
                } label: {
                    Text("A−")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help("Decrease font size  (−)")
                .accessibilityLabel("Decrease font size")

                Button {
                    viewModel.increaseFontSize()
                } label: {
                    Text("A+")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help("Increase font size  (+)")
                .accessibilityLabel("Increase font size")
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    // MARK: - Text content

    @ViewBuilder
    private func textContent(containerWidth: CGFloat) -> some View {
        Text(viewModel.displayAttributedText)
            .font(.system(size: viewModel.fontSize))
            .foregroundColor(viewModel.textColor)
            .multilineTextAlignment(.leading)
            .lineSpacing(6)
            .padding(.horizontal, 24)
            .padding(.top, 36)   // room for chrome strip
            .padding(.bottom, 64)
            .frame(width: containerWidth, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            .background(
                GeometryReader { g in
                    Color.clear
                        .onAppear    { viewModel.contentHeight = g.size.height }
                        .onChange(of: g.size.height) { _, h in viewModel.contentHeight = h }
                }
            )
            .offset(y: -viewModel.scrollOffset)
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        let fraction = viewModel.maxScrollOffset > 0
            ? viewModel.scrollOffset / viewModel.maxScrollOffset
            : 0

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.15))
                Capsule().fill(Color.white.opacity(0.65))
                    .frame(width: max(8, geo.size.width * fraction))
            }
        }
        .frame(height: 3)
    }

    private var progressAccessibilityValue: String {
        let pct = viewModel.maxScrollOffset > 0
            ? Int((viewModel.scrollOffset / viewModel.maxScrollOffset) * 100)
            : 0
        return "\(pct) percent"
    }

    // MARK: - End-of-script

    private func checkForNaturalEnd() {
        guard viewModel.maxScrollOffset > 0,
              viewModel.scrollOffset >= viewModel.maxScrollOffset - 2
        else { return }
        animate { showEndBanner = true }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            animate { showEndBanner = false }
        }
    }

    // MARK: - Animation helper (respects Reduce Motion)

    private func animate(_ body: () -> Void) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
            body()
        }
    }
}
