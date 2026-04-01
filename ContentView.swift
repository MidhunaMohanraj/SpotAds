import SwiftUI

// MARK: - Main Demo Screen

struct ContentView: View {

    @State private var selectedFormat: AdFormat = .banner
    @State private var showVideoAd = false
    @StateObject private var analytics = AnalyticsService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    formatPicker
                    adPreviewSection
                    analyticsSection
                }
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("SpotAds")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                NavigationLink("Event Log") {
                    EventLogView()
                }
            }
        }
        .fullScreenCover(isPresented: $showVideoAd) {
            VideoAdView()
        }
    }

    // MARK: - Format Picker

    private var formatPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Ad Format")
            Picker("Format", selection: $selectedFormat) {
                ForEach(AdFormat.allCases, id: \.self) { format in
                    Text(format.rawValue.capitalized).tag(format)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Ad Preview

    @ViewBuilder
    private var adPreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Live Preview")

            switch selectedFormat {
            case .banner:
                BannerAdView(config: .bannerPreview)
            case .video:
                VideoAdLaunchCard(showVideo: $showVideoAd)
            case .audio:
                AudioAdView(config: .audioPreview)
            case .interstitial:
                InterstitialAdCard()
            }
        }
    }

    // MARK: - Analytics Summary

    private var analyticsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Analytics Summary")
            AnalyticsSummaryCard(events: analytics.eventLog)
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 20)
    }
}

// MARK: - Video Launch Card

struct VideoAdLaunchCard: View {
    @Binding var showVideo: Bool
    var body: some View {
        Button { showVideo = true } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Video Ad (30s)")
                        .font(.headline).foregroundColor(.primary)
                    Text("Tap to launch full-screen video with skip & quartile tracking")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.green)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Interstitial Card

struct InterstitialAdCard: View {
    @State private var vm = AdViewModel(config: PlacementConfig(
        placementId: "placement-interstitial-playlist",
        format: .interstitial,
        skipAllowedAfterSeconds: nil,
        maxRefreshInterval: 0,
        targeting: TargetingParams(userId: nil, locale: "en_US", contentCategory: nil, ageGroup: nil)
    ))

    var body: some View {
        Group {
            if let ad = vm.currentAd {
                ZStack(alignment: .topLeading) {
                    AdAsyncImage(url: ad.imageURL, aspectRatio: 3/4, cornerRadius: 16)
                        .padding(.horizontal, 16)

                    VStack(alignment: .leading) {
                        AdBadge().padding(12)
                        Spacer()
                        VStack(alignment: .leading, spacing: 8) {
                            Text(ad.title).font(.title2.bold()).foregroundColor(.white)
                            CTAButton(label: ad.ctaLabel) { vm.didTapCTA() }
                        }
                        .padding(20)
                        .background(LinearGradient(colors: [.black.opacity(0.8), .clear], startPoint: .bottom, endPoint: .top))
                    }
                    .padding(.horizontal, 16)
                }
                .onAppear { vm.didAppear() }
            } else {
                ProgressView().onAppear { vm.loadAd() }
            }
        }
    }
}

// MARK: - Analytics Summary Card

struct AnalyticsSummaryCard: View {
    let events: [AdEvent]

    private var grouped: [String: Int] {
        Dictionary(grouping: events, by: { $0.eventType.rawValue })
            .mapValues { $0.count }
    }

    var body: some View {
        VStack(spacing: 0) {
            if grouped.isEmpty {
                Text("No events yet — interact with an ad")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(20)
            } else {
                ForEach(grouped.sorted(by: { $0.key < $1.key }), id: \.key) { key, count in
                    HStack {
                        Circle()
                            .fill(colorFor(key))
                            .frame(width: 8, height: 8)
                        Text(key.capitalized)
                            .font(.system(size: 14))
                        Spacer()
                        Text("\(count)")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    Divider().padding(.leading, 36)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        .padding(.horizontal, 16)
    }

    private func colorFor(_ event: String) -> Color {
        switch event {
        case "impression": return .green
        case "click":      return .blue
        case "skip":       return .orange
        case "complete":   return .purple
        default:           return .secondary
        }
    }
}

// MARK: - Event Log Screen

struct EventLogView: View {
    @ObservedObject private var analytics = AnalyticsService.shared
    private let formatter = ISO8601DateFormatter()

    var body: some View {
        List(analytics.eventLog.reversed()) { event in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.eventType.rawValue.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                    Spacer()
                    Text(formatter.string(from: event.timestamp))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Text("ad: \(event.adId)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                Text("placement: \(event.placementId)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .listRowBackground(Color(.secondarySystemBackground))
        }
        .navigationTitle("Event Log")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
    }
}

extension AdEvent: Identifiable {
    var id: String { "\(adId)-\(eventType.rawValue)-\(timestamp.timeIntervalSince1970)" }
}

#Preview {
    ContentView()
}
