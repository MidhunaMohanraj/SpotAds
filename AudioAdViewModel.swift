import Foundation
import AVFoundation
import Combine

// MARK: - Audio Ad ViewModel

@MainActor
final class AudioAdViewModel: AdViewModel {

    @Published private(set) var progress: Double = 0
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var isPlaying: Bool = false

    private var audioPlayer: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    func prepareAudio() {
        guard let ad = currentAd, let audioURL = ad.audioURL else { return }

        let item = AVPlayerItem(url: audioURL)
        let player = AVPlayer(playerItem: item)
        self.audioPlayer = player

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self, let duration = ad.durationSeconds else { return }
            let elapsed = time.seconds
            let total = Double(duration)
            self.progress = min(elapsed / total, 1.0)
            self.remainingSeconds = max(Int(total - elapsed), 0)
        }

        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleCompletion() }
            .store(in: &cancellables)
    }

    func play() {
        audioPlayer?.play()
        isPlaying = true
        didAppear()
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }

    private func handleCompletion() {
        isPlaying = false
        didComplete()
    }

    deinit {
        if let observer = timeObserver {
            audioPlayer?.removeTimeObserver(observer)
        }
    }
}
