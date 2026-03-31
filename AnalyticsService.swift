import Foundation
import Combine

// MARK: - Protocol

protocol AnalyticsServiceProtocol {
    func track(_ event: AdEvent)
    var eventLog: [AdEvent] { get }
}

// MARK: - Analytics Service

final class AnalyticsService: AnalyticsServiceProtocol, ObservableObject {

    static let shared = AnalyticsService()

    @Published private(set) var eventLog: [AdEvent] = []

    private let networkService: AdNetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(networkService: AdNetworkServiceProtocol = MockAdNetworkService()) {
        self.networkService = networkService
    }

    func track(_ event: AdEvent) {
        DispatchQueue.main.async {
            self.eventLog.append(event)
        }
        // Fire-and-forget beacon
        networkService.recordEvent(event)
            .sink {}
            .store(in: &cancellables)

        #if DEBUG
        print("[AdAnalytics] \(event.eventType.rawValue.uppercased()) — adId:\(event.adId) placement:\(event.placementId)")
        #endif
    }

    // MARK: - Convenience helpers

    func trackImpression(for payload: AdPayload) {
        track(AdEvent(type: .impression, payload: payload))
    }

    func trackClick(for payload: AdPayload) {
        track(AdEvent(type: .click, payload: payload))
    }

    func trackSkip(for payload: AdPayload) {
        track(AdEvent(type: .skip, payload: payload))
    }

    func trackComplete(for payload: AdPayload) {
        track(AdEvent(type: .complete, payload: payload))
    }

    func trackQuartile(_ quartile: AdEvent.EventType, for payload: AdPayload) {
        track(AdEvent(type: quartile, payload: payload))
    }
}
