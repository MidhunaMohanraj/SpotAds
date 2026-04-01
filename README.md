# SpotAds — iOS Ad Experience SDK Demo

> A production-quality demonstration of a Spotify-inspired mobile advertising platform built for iOS. Features non-interruptive banner, video, and audio ad experiences — the same surfaces Spotify's Advertising Product & Technology team maintains for hundreds of millions of listeners.

---

## Overview

SpotAds is a Swift/SwiftUI project that simulates a real-world mobile ad SDK. It covers the full ad lifecycle: request → impression → engagement → completion, with proper analytics tracking, quartile firing, skip logic, and graceful error handling.

The project was built to mirror the kind of work done on a platform-scale advertising team — reusable components, clean architecture, and observable state management with Combine.

---

## Features

### Ad Formats
| Format | Description |
|---|---|
| **Banner** | Lightweight persistent banner with shimmer loading state and live refresh |
| **Video** | Full-screen pre-roll with skip unlock timer, mute toggle, and IAB quartile tracking |
| **Audio** | Spotify-style between-tracks overlay with waveform animation and playback controls |
| **Interstitial** | Full-bleed image takeover with gradient overlay and CTA |

### Core Capabilities
- **Ad Lifecycle State Machine** — `AdState` enum drives all UI transitions (idle → loading → ready → playing → completed / failed)
- **IAB Quartile Tracking** — Video ads fire `quartile25`, `quartile50`, `quartile75`, and `complete` events automatically via `AVPlayer` time observer
- **Skip Logic** — Skip button unlocks after a configurable delay, matching industry-standard pre-roll behavior
- **Analytics Engine** — All interactions (impression, click, skip, complete, error) are tracked via `AnalyticsService` with a live event log in-app
- **Shimmer Loading States** — Skeleton placeholders on every ad surface before content loads
- **Graceful No-Fill Handling** — Ads fail silently (no broken UI) when inventory is unavailable
- **Targeting Params** — Placement configs carry locale, content category, and age group for real-world targeting simulation

---

## Architecture

```
SpotAds/
├── Models/
│   └── AdModels.swift          # AdPayload, AdFormat, AdState, AdError, AdEvent, PlacementConfig
├── Services/
│   ├── AdNetworkService.swift  # Protocol + MockAdNetworkService with realistic latency
│   └── AnalyticsService.swift  # Shared analytics engine, beacon dispatch
├── ViewModels/
│   ├── AdViewModel.swift       # Base VM — load, impression, click, skip
│   ├── VideoAdViewModel.swift  # AVPlayer, quartile tracking, skip unlock
│   └── AudioAdViewModel.swift  # AVPlayer audio, progress, play/pause
└── Views/
    ├── Components/
    │   ├── AdComponents.swift  # AdBadge, CTAButton, SkipButton, AdProgressBar, ShimmerView
    │   ├── BannerAdView.swift
    │   ├── VideoAdView.swift
    │   └── AudioAdView.swift
    └── Screens/
        └── ContentView.swift   # Demo shell + Event Log screen
```

**Pattern:** MVVM + Combine  
**Dependency flow:** Views observe ViewModels (`@StateObject`) → ViewModels call Services → Services return `AnyPublisher` streams

---

## Tech Stack

| Technology | Usage |
|---|---|
| **SwiftUI** | All UI — views, animations, transitions |
| **Combine** | Reactive ad fetch pipeline, state propagation |
| **AVFoundation / AVKit** | Video + audio playback, periodic time observer for quartiles |
| **async/await compatible** | Protocol-oriented service layer ready for async adoption |
| **XCTest** | Unit tests for ViewModel state transitions and analytics event firing |

---

## Getting Started

### Requirements
- Xcode 15+
- iOS 17+ deployment target
- No external dependencies (zero CocoaPods / SPM packages required)

### Run
```bash
git clone https://github.com/YOUR_USERNAME/SpotAds.git
cd SpotAds
open SpotAds.xcodeproj
```
Select any simulator running iOS 17+ and press **Run**.

---

## How It Works

### Ad Request Flow
```
PlacementConfig
    └─> AdViewModel.loadAd()
            └─> AdNetworkService.fetchAd(for:)  ← returns AnyPublisher<AdPayload, AdError>
                    └─> AdPayload published to @Published currentAd
                            └─> View renders ad content
                                    └─> AnalyticsService.trackImpression()
```

### Video Quartile Tracking
```swift
// VideoAdViewModel.swift
player.addPeriodicTimeObserver(...) { time in
    let progress = time.seconds / Double(duration)
    // Fires once per milestone, guarded by quartilesFired Set
    checkQuartiles(progress: progress, payload: ad)
}
```

### Analytics Events
Every user interaction fires a structured `AdEvent`:
```
request → impression → [quartile25] → [quartile50] → [quartile75] → complete
                    ↘ click
                    ↘ skip
```
All events are visible in the in-app **Event Log** tab and logged to console in DEBUG builds.

---

## Testing

Unit tests cover:
- `AdViewModel` state transitions (idle → loading → ready → completed)
- Analytics event ordering and deduplication
- Quartile thresholds and guard against double-firing
- `AdNetworkService` no-fill error propagation

```bash
Cmd+U  # Run all tests in Xcode
```

---

## Design Decisions

**Why Combine over async/await for the ad pipeline?**  
Combine's `AnyPublisher` makes it easy to chain timeout operators, retry logic, and fallback publishers — all common requirements in production ad SDKs. The protocol layer is async/await friendly if needed.

**Why a shared `AnalyticsService` singleton?**  
Ad analytics must survive view lifecycle — a singleton ensures events fired during transitions (e.g. skip mid-scroll) are never lost. In production this would be backed by a persistent queue.

**Why mock data instead of a real ad server?**  
This keeps the project self-contained and runnable without credentials, while still exercising the full network/parsing/error path through `MockAdNetworkService`.

---

## Roadmap

- [ ] VAST/VPAID XML parsing for real ad server integration  
- [ ] Companion banner alongside audio ads  
- [ ] Viewability tracking (>50% on screen for >1 second)  
- [ ] A/B creative rotation per placement  
- [ ] Offline retry queue for missed impression beacons  

---

## License

MIT
