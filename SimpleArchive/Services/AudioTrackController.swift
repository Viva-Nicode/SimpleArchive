import AVFoundation
import CSFBAudioEngine

protocol AudioTrackControllerType {
    var player: AVAudioPlayer? { get }
    var isPlaying: Bool { get }
    var totalTime: TimeInterval? { get }
    var currentTime: TimeInterval? { get }
    var audioTrackURL: URL? { get }

    func setAudioURL(audioURL: URL)
    func play()
    func togglePlaying()
    func seek(interval: TimeInterval)
    func reset()
}

final class AudioTrackController: NSObject, AudioTrackControllerType {

    private(set) var player: AVAudioPlayer?
    private(set) var audioTrackURL: URL?

    deinit { print("deinit AudioTrackController") }

    var isPlaying: Bool {
        player?.isPlaying ?? false
    }

    var totalTime: TimeInterval? {
        player?.duration
    }

    var currentTime: TimeInterval? {
        player?.currentTime
    }

    func setAudioURL(audioURL: URL) {
        self.audioTrackURL = audioURL
        preparePlayer()
    }

    func play() {
        guard let player = player else {
            preparePlayer()
            self.player?.play()
            return
        }
        if !player.isPlaying {
            player.play()
        }
    }

    func togglePlaying() {
        guard let player = player else { return }
        if player.isPlaying {
            player.pause()
        } else {
            player.play()
        }
    }

    func seek(interval: TimeInterval) {
        guard let player = player else { return }
        let newTime = max(0, min(interval, player.duration))
        player.currentTime = newTime
    }

    func reset() {
        player?.stop()
        player?.delegate = nil

        player = nil
        audioTrackURL = nil
    }

    private func preparePlayer() {
        do {
            guard let audioURL = audioTrackURL else { return }
            player = try AVAudioPlayer(contentsOf: audioURL)
            player?.prepareToPlay()
        } catch {
            print("AVAudioPlayer 초기화 실패: \(error.localizedDescription)")
        }
    }
}
