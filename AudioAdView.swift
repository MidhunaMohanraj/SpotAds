import SwiftUI

// MARK: - Audio Ad View (Spotify-style overlay between tracks)

struct AudioAdView: View {

    @StateObject private var viewModel: AudioAdViewModel

    init(config: PlacementConfig = .audioPreview) {
        _viewModel = StateObject(wrappedValue: AudioAdViewModel(config: config))
    }

    var body: some View {
        Group {
            switch viewModel.adState {
            case .idle:
                Color.clear.onAppear { viewModel.loadAd() }
            case .loading:
                loadingCard
                    .onReceive(viewModel.$currentAd.compactMap { $0 }) { _ in
                        viewModel.prepareAudio()
                        viewModel.play()
                    }
            case .ready, .playing, .paused:
                if let ad = viewModel.currentAd {
                    adCard(ad: ad)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            case .completed:
                completedBanner
            default:
                EmptyView()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.adState.isVisible)
    }

    // MARK: - Ad Card

    @ViewBuilder
    private func adCard(ad: AdPayload) -> some View {
        VStack(spacing: 0) {
            // Waveform animation + album art row
            HStack(spacing: 16) {
                ZStack {
                    AdAsyncImage(url: ad.imageURL, aspectRatio: 1, cornerRadius: 8)
                        .frame(width: 56, height: 56)
                    if viewModel.isPlaying {
                        WaveformView()
                            .frame(width: 56, height: 56)
                            .background(Color.black.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        AdBadge()
                        Text(ad.advertiser)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Text(ad.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }

                Spacer()

                // Play/Pause toggle (audio ads only pause — no skip)
                Button {
                    viewModel.isPlaying ? viewModel.pause() : viewModel.play()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.green)
                }
            }
            .padding(16)

            // Progress
            AdProgressBar(progress: viewModel.progress, tint: .green)
                .padding(.horizontal, 16)

            // CTA strip
            HStack {
                Text("\(viewModel.remainingSeconds)s remaining")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
                CTAButton(label: ad.ctaLabel) {
                    viewModel.didTapCTA()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 12, y: -4)
        )
        .padding(.horizontal, 12)
    }

    // MARK: - Loading

    private var loadingCard: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 56, height: 56)
                .overlay(ShimmerView())

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 10)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 160, height: 14)
            }
            Spacer()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
        .padding(.horizontal, 12)
    }

    // MARK: - Completed

    private var completedBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            Text("Ad finished — enjoy your music!").font(.subheadline).foregroundColor(.secondary)
            Spacer()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
        .padding(.horizontal, 12)
    }
}

// MARK: - Waveform Animation

struct WaveformView: View {
    @State private var animating = false

    private let barCount = 5

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<barCount, id: \.self) { i in
                Capsule()
                    .fill(Color.green)
                    .frame(width: 3)
                    .frame(height: animating ? CGFloat.random(in: 8...28) : 4)
                    .animation(
                        .easeInOut(duration: Double.random(in: 0.3...0.6))
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.1),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        VStack {
            Spacer()
            AudioAdView()
        }
    }
}
