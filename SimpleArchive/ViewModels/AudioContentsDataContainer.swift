import Foundation
import QuartzCore

protocol AudioContentsDataContainerType {
    func getAudioContentsData(_ id: UUID) -> AudioContentsData?
}

final class AudioContentsDataContainer: AudioContentsDataContainerType {

    private var audioContentsDataTable: [UUID: AudioContentsData] = [:]

    init(audioContentsDataTable: [UUID: AudioContentsData]) {
        self.audioContentsDataTable = audioContentsDataTable
    }

    func getAudioContentsData(_ id: UUID) -> AudioContentsData? {
        audioContentsDataTable[id]
    }

    subscript(id: UUID) -> AudioContentsData? {
        get { audioContentsDataTable[id] }
        set { audioContentsDataTable[id] = newValue }
    }

    var activeAudioContentsData: AudioContentsData? {
        audioContentsDataTable
            .values
            .filter { $0.activeAudioTrackData != nil }
            .first
    }
}

final class AudioContentsData {
    var audioComponent: AudioComponent
    var activeAudioTrackData: ActiveAudioTrackData?

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

final class ActiveAudioTrackData {
    var audioVisualizerData: AudioWaveformData?

    var totalTime: TimeInterval?
    var startTime: TimeInterval = 0
    var pauseTime: TimeInterval?
    var passedTime: TimeInterval = 0

    var nowPlayingAudioTrackID: UUID?
    var isPlaying: Bool?

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
        audioVisualizerData = nil

        totalTime = nil
        pauseTime = nil
        startTime = 0
        passedTime = 0
    }
}
