import Foundation
import QuartzCore

final class ActiveAudioTrackVisualizerData: PlayBackVisualizer {
    var nowPlayingAudioComponentID: UUID?
    var nowPlayingAudioTrackID: UUID?
    var isPlaying: Bool?

    var totalTime: TimeInterval?
    var startTime: TimeInterval = 0
    var pauseTime: TimeInterval?
    var passedTime: TimeInterval = 0

    var waveformData: AudioWaveformData?

    func setupNewVisualizerData(
        nowPlayingAudioComponentID: UUID,
        nowPlayingAudioTrackID: UUID,
        totalTime: TimeInterval?,
        waveformData: AudioWaveformData?
    ) {
        self.nowPlayingAudioComponentID = nowPlayingAudioComponentID
        self.nowPlayingAudioTrackID = nowPlayingAudioTrackID
        self.totalTime = totalTime
        self.waveformData = waveformData
        self.startTime = CACurrentMediaTime()
        self.isPlaying = true
    }

    func hasChangePlayingState() {
        if let pauseTime {
            let currentTime = CACurrentMediaTime()
            passedTime += currentTime - pauseTime
            self.pauseTime = nil
        } else {
            pauseTime = CACurrentMediaTime()
        }
    }

    func seek(seek: TimeInterval) {
        let currentTime = CACurrentMediaTime()
        startTime = currentTime - seek

        pauseTime = nil
        passedTime = 0
    }

    func clean() {
        nowPlayingAudioTrackID = nil
        isPlaying = nil
        waveformData = nil

        totalTime = nil
        pauseTime = nil
        startTime = 0
        passedTime = 0
    }

    func replaceVisualizerData(other: ActiveAudioTrackVisualizerData) {
        self.isPlaying = other.isPlaying

        self.nowPlayingAudioComponentID = other.nowPlayingAudioComponentID
        self.nowPlayingAudioTrackID = other.nowPlayingAudioTrackID

        self.totalTime = other.totalTime
        self.startTime = other.startTime
        self.pauseTime = other.pauseTime
        self.passedTime = other.passedTime

        self.waveformData = other.waveformData
    }

    func playbackVisualizer(componentID: UUID, trackID: UUID, audioVisualizer: any AudioVisualizerController) {
        if nowPlayingAudioComponentID == componentID, nowPlayingAudioTrackID == trackID {
            if let isPlaying = isPlaying,
                let totalTime = totalTime,
                let audioVisualizerData = waveformData
            {
                let baseTime = pauseTime ?? CACurrentMediaTime()
                let passedTime = baseTime - startTime - passedTime
                let progressRatio = passedTime / totalTime

                DispatchQueue.main.async {
                    audioVisualizer.activateAudioVisualizer(waveFormData: audioVisualizerData)
                    audioVisualizer.seekVisuzlization(rate: progressRatio)
                    if !isPlaying {
                        audioVisualizer.pauseVisuzlization()
                    }
                }
            }
        }
    }
}

struct AudioWaveformData: Codable, Equatable {
    var sampleDataCount: Int
    var sampleRate: Double
    var waveformData: [[Float]]
}

protocol PlayBackVisualizer {
    func playbackVisualizer(componentID: UUID, trackID: UUID, audioVisualizer: AudioVisualizerController)
}

final class AudioContentsData {
    var audioComponent: AudioComponent
    var activeAudioTrackData: ActiveAudioTrackVisualizerData?

    init(audioComponent: AudioComponent) {
        self.audioComponent = audioComponent
    }

    func clean() {
        activeAudioTrackData?.clean()
        activeAudioTrackData = nil
    }

    func hasChangePlayingState() {
        activeAudioTrackData?.hasChangePlayingState()
    }

    func seek(seek: TimeInterval) {
        activeAudioTrackData?.seek(seek: seek)
    }
}
