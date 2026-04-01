import SwiftUI
import AVKit

// MARK: - Video Ad View

struct VideoAdView: View {

    @StateObject private var viewModel: VideoAdViewModel
    @Environment(\.dismiss) private var dismiss

    init(config: PlacementConfig = .videoPreview) {
        _viewModel = StateObject(wrappedValue: VideoAdViewModel(config: config))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.adState {
            case .idle:
                Color.clear.onAppear { viewModel.loadAd() }

            case .loading:
                ProgressView()
                    .tint(.white)
                    .onReceive(viewModel.$currentAd.compactMap { $0 }) { _ in
                        viewModel.preparePlayer()
                    }

            case .ready, .playing, .paused:
                if let player = viewModel.player {
                    videoLayer(player: player)
                }

            case .completed:
                completedView

            case .failed(let error):
                failedView(error: error)
            }
        }
        .onDisappear { viewModel.pause() }
    }

    // MARK: - Video Layer

    @ViewBuilder
    private func videoLayer(player: AVPlayer) -> some View {
        ZStack(alignment: .bottom) {
            // AVPlayer
            VideoPlayer(player: player)
                .ignoresSafeArea()
                .onAppear { viewModel.play() }

            // Overlay Controls
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    AdBadge()
                    Spacer()
                    muteButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer()

                // Bottom controls
                VStack(spacing: 12) {
                    if let ad = viewModel.currentAd {
                        advertiserBar(ad: ad)
                    }

                    AdProgressBar(progress: viewModel.progress)
                        .padding(.horizontal, 16)

                    HStack {
                        if let ad = viewModel.currentAd {
                            timeLabel
                            Spacer()
                            CTAButton(label: ad.ctaLabel) {
                                viewModel.didTapCTA()
                            }
                        }
                        Spacer()
                        SkipButton(
                            canSkip: viewModel.canSkip,
                            remaining: viewModel.remainingSeconds,
                            action: { viewModel.didSkip() }
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }

    // MARK: - Sub-views

    private var muteButton: some View {
        Button {
            viewModel.isMuted.toggle()
        } label: {
            Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(8)
                .background(Color.black.opacity(0.4))
                .clipShape(Circle())
        }
    }

    private var timeLabel: some View {
        Text("\(viewModel.remainingSeconds)s")
            .font(.system(size: 13, weight: .medium, design: .monospaced))
            .foregroundColor(.white.opacity(0.8))
    }

    @ViewBuilder
    private func advertiserBar(ad: AdPayload) -> some View {
        HStack(spacing: 10) {
            AdAsyncImage(url: ad.imageURL, aspectRatio: 1, cornerRadius: 4)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(ad.advertiser)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Text(ad.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Completed / Error

    private var completedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            Text("Ad complete")
                .font(.headline)
                .foregroundColor(.white)
        }
    }

    private func failedView(error: AdError) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.yellow)
            Text(error.errorDescription ?? "Something went wrong")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    VideoAdView()
}
