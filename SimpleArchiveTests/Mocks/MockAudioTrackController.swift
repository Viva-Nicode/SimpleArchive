import AVFoundation
import CSFBAudioEngine
import Foundation

@testable import SimpleArchive

final class MockAudioTrackController: Mock, AudioTrackControllerType {

    enum Action: Equatable {
        case setAudioURL
        case play
        case togglePlaying
        case seek
        case reset
        case isPlaying
        case totalTime
        case currentTime
    }

    var actions = MockActions<Action>(expected: [])

    var isPlayingResult: Bool!
    var totalTimeResult: TimeInterval!
    var currentTimeResult: TimeInterval!

    var player: AVAudioPlayer?
    var audioTrackURL: URL?

    var isPlaying: Bool {
        register(.isPlaying)
        return isPlayingResult
    }

    var totalTime: TimeInterval? {
        register(.totalTime)
        return totalTimeResult
    }

    var currentTime: TimeInterval? {
        register(.currentTime)
        return currentTimeResult
    }

    func setAudioURL(audioURL: URL) {
        register(.setAudioURL)
    }

    func play() {
        register(.play)
    }

    func togglePlaying() {
        register(.togglePlaying)
    }

    func seek(interval: TimeInterval) {
        register(.seek)
    }

    func reset() {
        register(.reset)
    }
}
