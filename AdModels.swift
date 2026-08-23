import Foundation

// MARK: - Ad Types

enum AdFormat: String, Codable, CaseIterable {
    case banner      = "banner"
    case video       = "video"
    case audio       = "audio"
    case interstitial = "interstitial"
}
enum AdState {
    case idle
    case loading
    case ready
    case playing
    case paused
    case completed
    case failed(AdError)
}

enum AdError: Error, LocalizedError {
    case networkFailure
    case timeout
    case invalidPayload
    case unsupportedFormat
    case noFill

    var errorDescription: String? {
        switch self {
        case .networkFailure:   return "Network request failed."
        case .timeout:          return "Ad request timed out."
        case .invalidPayload:   return "Received malformed ad payload."
        case .unsupportedFormat: return "Ad format not supported on this device."
        case .noFill:           return "No ad available for this placement."
        }
    }
}

// MARK: - Ad Payload

struct AdPayload: Identifiable, Codable, Equatable {
    let id: String
    let format: AdFormat
    let title: String
    let advertiser: String
    let ctaLabel: String
    let ctaURL: URL
    let impressionURL: URL?
    let clickURL: URL?

    // Media
    let imageURL: URL?
    let videoURL: URL?
    let audioURL: URL?
    let durationSeconds: Int?

    // Targeting metadata
    let campaignId: String
    let placementId: String
    let priority: Int          // 1 (highest) – 10 (lowest)
}

// MARK: - Ad Event (Analytics)

struct AdEvent: Codable {
    enum EventType: String, Codable {
        case request
        case impression
        case click
        case skip
        case complete
        case error
        case quartile25
        case quartile50
        case quartile75
    }

    let eventType: EventType
    let adId: String
    let placementId: String
    let campaignId: String
    let timestamp: Date
    let metadata: [String: String]

    init(type: EventType, payload: AdPayload, metadata: [String: String] = [:]) {
        self.eventType = type
        self.adId = payload.id
        self.placementId = payload.placementId
        self.campaignId = payload.campaignId
        self.timestamp = Date()
        self.metadata = metadata
    }
}

// MARK: - Placement Config

struct PlacementConfig {
    let placementId: String
    let format: AdFormat
    let skipAllowedAfterSeconds: Int?   // nil = not skippable
    let maxRefreshInterval: TimeInterval // how often banner refreshes
    let targeting: TargetingParams
}

struct TargetingParams {
    let userId: String?
    let locale: String
    let contentCategory: String?   // e.g. "pop", "podcast"
    let ageGroup: String?          // e.g. "18-24"
}
