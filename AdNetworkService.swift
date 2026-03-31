import Foundation
import Combine

// MARK: - Protocol

protocol AdNetworkServiceProtocol {
    func fetchAd(for config: PlacementConfig) -> AnyPublisher<AdPayload, AdError>
    func recordEvent(_ event: AdEvent) -> AnyPublisher<Void, Never>
}

// MARK: - Mock Ad Network Service

final class MockAdNetworkService: AdNetworkServiceProtocol {

    private let mockDelay: TimeInterval

    init(mockDelay: TimeInterval = 0.8) {
        self.mockDelay = mockDelay
    }

    func fetchAd(for config: PlacementConfig) -> AnyPublisher<AdPayload, AdError> {
        // Simulate network latency
        return Future<AdPayload, AdError> { [weak self] promise in
            guard let self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + self.mockDelay) {
                if let ad = Self.mockAds.first(where: { $0.format == config.format }) {
                    promise(.success(ad))
                } else {
                    promise(.failure(.noFill))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func recordEvent(_ event: AdEvent) -> AnyPublisher<Void, Never> {
        // In production this would POST to your impression/click beacon endpoint
        return Just(())
            .delay(for: .milliseconds(200), scheduler: DispatchQueue.global())
            .eraseToAnyPublisher()
    }

    // MARK: - Mock Data

    static let mockAds: [AdPayload] = [
        AdPayload(
            id: "ad-banner-001",
            format: .banner,
            title: "Premium Sound. Zero Compromise.",
            advertiser: "Bose",
            ctaLabel: "Shop Now",
            ctaURL: URL(string: "https://www.bose.com")!,
            impressionURL: URL(string: "https://ads.example.com/impression/banner-001")!,
            clickURL: URL(string: "https://ads.example.com/click/banner-001")!,
            imageURL: URL(string: "https://picsum.photos/seed/bose/600/200")!,
            videoURL: nil,
            audioURL: nil,
            durationSeconds: nil,
            campaignId: "camp-bose-q4",
            placementId: "placement-banner-home",
            priority: 1
        ),
        AdPayload(
            id: "ad-video-001",
            format: .video,
            title: "The New MacBook Pro",
            advertiser: "Apple",
            ctaLabel: "Learn More",
            ctaURL: URL(string: "https://www.apple.com/macbook-pro")!,
            impressionURL: URL(string: "https://ads.example.com/impression/video-001")!,
            clickURL: URL(string: "https://ads.example.com/click/video-001")!,
            imageURL: URL(string: "https://picsum.photos/seed/apple-mbp/800/450")!,
            videoURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!,
            audioURL: nil,
            durationSeconds: 30,
            campaignId: "camp-apple-mbp",
            placementId: "placement-video-player",
            priority: 1
        ),
        AdPayload(
            id: "ad-audio-001",
            format: .audio,
            title: "Spotify Premium — Listen Without Limits",
            advertiser: "Spotify",
            ctaLabel: "Get Premium",
            ctaURL: URL(string: "https://spotify.com/premium")!,
            impressionURL: URL(string: "https://ads.example.com/impression/audio-001")!,
            clickURL: URL(string: "https://ads.example.com/click/audio-001")!,
            imageURL: URL(string: "https://picsum.photos/seed/spotify/400/400")!,
            videoURL: nil,
            audioURL: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")!,
            durationSeconds: 30,
            campaignId: "camp-spotify-premium",
            placementId: "placement-audio-between-tracks",
            priority: 2
        ),
        AdPayload(
            id: "ad-interstitial-001",
            format: .interstitial,
            title: "Try Nike Run Club — Free",
            advertiser: "Nike",
            ctaLabel: "Download Now",
            ctaURL: URL(string: "https://www.nike.com/nrc-app")!,
            impressionURL: URL(string: "https://ads.example.com/impression/interstitial-001")!,
            clickURL: URL(string: "https://ads.example.com/click/interstitial-001")!,
            imageURL: URL(string: "https://picsum.photos/seed/nike/800/1200")!,
            videoURL: nil,
            audioURL: nil,
            durationSeconds: nil,
            campaignId: "camp-nike-nrc",
            placementId: "placement-interstitial-playlist",
            priority: 3
        )
    ]
}
