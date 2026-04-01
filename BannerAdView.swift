import SwiftUI

// MARK: - Banner Ad View

struct BannerAdView: View {

    @StateObject private var viewModel: AdViewModel

    init(config: PlacementConfig = .bannerPreview) {
        _viewModel = StateObject(wrappedValue: AdViewModel(config: config))
    }

    var body: some View {
        Group {
            switch viewModel.adState {
            case .idle:
                Color.clear.onAppear { viewModel.loadAd() }

            case .loading:
                loadingView

            case .ready:
                if let ad = viewModel.currentAd {
                    bannerContent(ad: ad)
                        .onAppear { viewModel.didAppear() }
                        .transition(.opacity)
                }

            case .failed:
                errorView

            default:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.adState.isVisible)
    }

    // MARK: - Banner Content

    @ViewBuilder
    private func bannerContent(ad: AdPayload) -> some View {
        HStack(spacing: 12) {
            // Thumbnail
            AdAsyncImage(url: ad.imageURL, aspectRatio: 1, cornerRadius: 8)
                .frame(width: 64, height: 64)

            // Text
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    AdBadge()
                    Text(ad.advertiser)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Text(ad.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }

            Spacer()

            CTAButton(label: ad.ctaLabel) {
                viewModel.didTapCTA()
                openURL(ad.ctaURL)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Loading

    private var loadingView: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 64, height: 64)
                .overlay(ShimmerView())

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 120, height: 12)
                    .overlay(ShimmerView())
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 200, height: 14)
                    .overlay(ShimmerView())
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Error

    private var errorView: some View {
        EmptyView() // Graceful degradation — show nothing on no-fill
    }

    private func openURL(_ url: URL) {
        UIApplication.shared.open(url)
    }
}

// MARK: - AdState helper

extension AdState {
    var isVisible: Bool {
        switch self {
        case .ready, .playing, .paused: return true
        default: return false
        }
    }
}

// MARK: - Preview Config

extension PlacementConfig {
    static let bannerPreview = PlacementConfig(
        placementId: "placement-banner-home",
        format: .banner,
        skipAllowedAfterSeconds: nil,
        maxRefreshInterval: 30,
        targeting: TargetingParams(userId: "preview-user", locale: "en_US", contentCategory: "pop", ageGroup: "18-24")
    )

    static let videoPreview = PlacementConfig(
        placementId: "placement-video-player",
        format: .video,
        skipAllowedAfterSeconds: 5,
        maxRefreshInterval: 0,
        targeting: TargetingParams(userId: "preview-user", locale: "en_US", contentCategory: "pop", ageGroup: "18-24")
    )

    static let audioPreview = PlacementConfig(
        placementId: "placement-audio-between-tracks",
        format: .audio,
        skipAllowedAfterSeconds: nil,
        maxRefreshInterval: 0,
        targeting: TargetingParams(userId: "preview-user", locale: "en_US", contentCategory: "pop", ageGroup: "18-24")
    )
}

#Preview {
    BannerAdView()
        .padding(.vertical)
}
