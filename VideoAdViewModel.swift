import Foundation
import AVFoundation
import Combine

// MARK: - Video Ad ViewModel

@MainActor
final class VideoAdViewModel: AdViewModel {

    @Published private(set) var progress: Double = 0       // 0.0 – 1.0
    @Published private(set) var remainingSeconds: Int = 0
    @Published var isMuted: Bool = false
    @Published private(set) var canSkip: Bool = false

    private(set) var player: AVPlayer?
    private var timeObserver: Any?
    private var quartilesFired: Set<AdEvent.EventType> = []
    private var playerCancellables = Set<AnyCancellable>()

    // MARK: - Setup Player

    func preparePlayer() {
        guard let ad = currentAd, let videoURL = ad.videoURL else { return }

        let item = AVPlayerItem(url: videoURL)
        let avPlayer = AVPlayer(playerItem: item)
        avPlayer.isMuted = isMuted
        self.player = avPlayer

        // Observe mute toggle
        $isMuted
            .sink { [weak avPlayer] muted in avPlayer?.isMuted = muted }
            .store(in: &playerCancellables)

        // Periodic time observer — every 0.5s
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self, let ad = self.currentAd, let duration = ad.durationSeconds else { return }
            let elapsed = time.seconds
            let total = Double(duration)
            self.progress = min(elapsed / total, 1.0)
            self.remainingSeconds = max(Int(total - elapsed), 0)

            // Skip unlock
            if let skipAfter = self.config.skipAllowedAfterSeconds {
                self.canSkip = elapsed >= Double(skipAfter)
            }

            // Quartile tracking
            self.checkQuartiles(progress: self.progress, payload: ad)
        }

        // End observer
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.didComplete() }
            .store(in: &playerCancellables)

        adState = .ready
    }

    func play() {
        player?.play()
        adState = .playing
        didAppear()
    }

    func pause() {
        player?.pause()
        adState = .paused
    }

    override func didSkip() {
        player?.pause()
        super.didSkip()
    }

    override func didComplete() {
        player?.pause()
        super.didComplete()
    }

    // MARK: - Quartile Tracking

    private func checkQuartiles(progress: Double, payload: AdPayload) {
        let milestones: [(Double, AdEvent.EventType)] = [
            (0.25, .quartile25),
            (0.50, .quartile50),
            (0.75, .quartile75)
        ]
        for (threshold, eventType) in milestones {
            if progress >= threshold && !quartilesFired.contains(eventType) {
                quartilesFired.insert(eventType)
                analytics.trackQuartile(eventType, for: payload)
            }
        }
    }

    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
}
