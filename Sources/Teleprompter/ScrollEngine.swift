import Foundation

/// Drives smooth, time-delta–based auto-scrolling at ~60 Hz.
/// Owned by TeleprompterViewModel; uses a weak back-reference to avoid retain cycles.
@MainActor
final class ScrollEngine {

    private weak var viewModel: TeleprompterViewModel?
    private var timer: Timer?
    private var lastTick: Date?

    init(viewModel: TeleprompterViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Control

    func start() {
        guard timer == nil else { return }
        lastTick = Date()
        // Use target/selector to avoid Swift concurrency isolation issues.
        // The timer is added to RunLoop.main with .common mode so it fires even
        // during menu interactions and other UI run-loop activity.
        let t = Timer(timeInterval: 1.0 / 60.0,
                      target: self,
                      selector: #selector(tick),
                      userInfo: nil,
                      repeats: true)
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        lastTick = nil
    }

    // MARK: - Private

    @objc private func tick() {
        guard let vm = viewModel else { stop(); return }
        guard vm.isPlaying else { stop(); return }

        let now = Date()
        let elapsed = lastTick.map { now.timeIntervalSince($0) } ?? (1.0 / 60.0)
        lastTick = now

        let delta = vm.scrollSpeed * elapsed
        let newOffset = vm.scrollOffset + delta

        if newOffset >= vm.maxScrollOffset {
            vm.scrollOffset = vm.maxScrollOffset
            vm.isPlaying = false
            stop()
        } else {
            vm.scrollOffset = newOffset
        }
    }

    deinit {
        timer?.invalidate()
    }
}
