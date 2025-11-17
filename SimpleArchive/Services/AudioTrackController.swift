import AVFoundation
import CSFBAudioEngine
import UIKit

protocol AudioTrackControllerType {
    var player: AVAudioPlayer? { get }
    var isPlaying: Bool { get }
    var audioTrackURL: URL { get }
    func play()
    func stop()
    func togglePlaying()
    func getTotalTime() -> TimeInterval?
    func getCurrentTime() -> TimeInterval?
    func seek(interval: TimeInterval)
    func setDelegate(_ delegate: AVAudioPlayerDelegate)
}

final class AudioTrackController: NSObject, AudioTrackControllerType {

    private(set) var player: AVAudioPlayer?
    private(set) var audioTrackURL: URL

    init(audioTrackURL: URL) {
        self.audioTrackURL = audioTrackURL
        super.init()
        preparePlayer()
    }

    deinit { print("deinit AudioTrackController") }

    private func preparePlayer() {
        do {
            player = try AVAudioPlayer(contentsOf: audioTrackURL)
            player?.prepareToPlay()
        } catch {
            print("AVAudioPlayer 초기화 실패: \(error.localizedDescription)")
        }
    }

    func setDelegate(_ delegate: AVAudioPlayerDelegate) {
        self.player?.delegate = delegate
    }

    func togglePlaying() {
        guard let player = player else { return }
        if player.isPlaying {
            player.pause()
        } else {
            player.play()
        }
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

    func stop() {
        player?.stop()
    }

    var isPlaying: Bool {
        player?.isPlaying ?? false
    }

    func getTotalTime() -> TimeInterval? {
        player?.duration
    }

    func getCurrentTime() -> TimeInterval? {
        player?.currentTime
    }

    func seek(interval: TimeInterval) {
        guard let player = player else { return }
        let newTime = max(0, min(interval, player.duration))
        player.currentTime = newTime
    }
}
