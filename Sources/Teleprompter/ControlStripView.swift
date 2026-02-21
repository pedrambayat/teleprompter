import SwiftUI

/// Playback controls revealed at the bottom of the overlay on hover.
struct ControlStripView: View {

    @Bindable var viewModel: TeleprompterViewModel

    var body: some View {
        HStack(spacing: 20) {

            // Reset to top
            Button {
                viewModel.resetToTop()
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .help("Reset to top  (R)")
            .accessibilityLabel("Reset to top")

            // Play / Pause
            Button {
                viewModel.togglePlayback()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help(viewModel.isPlaying ? "Pause  (Space)" : "Play  (Space)")
            .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")

            // Speed slider
            HStack(spacing: 6) {
                Image(systemName: "tortoise")
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.system(size: 12))
                    .accessibilityHidden(true)

                Slider(value: $viewModel.scrollSpeed, in: 10...250)
                    .frame(width: 110)
                    .tint(.white)
                    .accessibilityLabel("Scroll speed")
                    .accessibilityValue("\(Int(viewModel.scrollSpeed)) points per second")

                Image(systemName: "hare")
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.system(size: 12))
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().fill(Color.black.opacity(0.45)))
        )
        .accessibilityElement(children: .contain)
    }
}
