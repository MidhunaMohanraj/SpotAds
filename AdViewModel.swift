import Foundation
import Combine

// MARK: - Base Ad ViewModel

@MainActor
class AdViewModel: ObservableObject {

    @Published private(set) var adState: AdState = .idle
    @Published private(set) var currentAd: AdPayload?
    @Published private(set) var errorMessage: String?

    let config: PlacementConfig

    private let networkService: AdNetworkServiceProtocol
    let analytics: AnalyticsService

    private var cancellables = Set<AnyCancellable>()

    init(
        config: PlacementConfig,
        networkService: AdNetworkServiceProtocol = MockAdNetworkService(),
        analytics: AnalyticsService = .shared
    ) {
        self.config = config
        self.networkService = networkService
        self.analytics = analytics
    }

    // MARK: - Load

    func loadAd() {
        adState = .loading
        errorMessage = nil

        networkService.fetchAd(for: config)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.adState = .failed(error)
                    self?.errorMessage = error.errorDescription
                }
            } receiveValue: { [weak self] payload in
                self?.currentAd = payload
                self?.adState = .ready
                self?.analytics.track(AdEvent(type: .request, payload: payload))
            }
            .store(in: &cancellables)
    }

    // MARK: - Interactions

    func didAppear() {
        guard let ad = currentAd else { return }
        analytics.trackImpression(for: ad)
    }

    func didTapCTA() {
        guard let ad = currentAd else { return }
        analytics.trackClick(for: ad)
    }

    func didSkip() {
        guard let ad = currentAd else { return }
        analytics.trackSkip(for: ad)
        adState = .completed
    }

    func didComplete() {
        guard let ad = currentAd else { return }
        analytics.trackComplete(for: ad)
        adState = .completed
    }
}
