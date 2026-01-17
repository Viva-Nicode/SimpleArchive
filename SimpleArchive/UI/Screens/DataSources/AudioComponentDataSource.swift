import UIKit

struct AudioWaveformData: Codable, Equatable {
    var sampleDataCount: Int
    var sampleRate: Double
    var waveformData: [[Float]]
}

final class AudioComponentDataSource: NSObject, UITableViewDataSource {
    var audioContentsData: AudioContentsData

    init(audioContentsData: AudioContentsData) {
        self.audioContentsData = audioContentsData
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        audioContentsData.audioComponent.componentContents.tracks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let track = audioContentsData.audioComponent.componentContents.tracks[indexPath.row]

        let audioTableRowView =
            tableView.dequeueReusableCell(
                withIdentifier: AudioTableRowView.reuseIdentifier,
                for: indexPath) as! AudioTableRowView

        audioTableRowView.configure(audioTrack: track)

        if let activeTrackData = audioContentsData.activeAudioTrackData,
            let totalTime = activeTrackData.totalTime,
            let audioVisualizerData = activeTrackData.audioVisualizerData
        {
            let currentTime = CACurrentMediaTime()
            let passedTime = currentTime - activeTrackData.startTime - activeTrackData.passedTime
            let progressRatio = passedTime / totalTime

            DispatchQueue.main.async {
                audioTableRowView.audioVisualizer.activateAudioVisualizer(waveFormData: audioVisualizerData)
                audioTableRowView.audioVisualizer.seekVisuzlization(rate: progressRatio)
                if activeTrackData.isPlaying == false {
                    audioTableRowView.audioVisualizer.pauseVisuzlization()
                }
            }
        }

        if audioTableRowView.isNeedSetupShadow {
            audioTableRowView.setupShadow()
            audioTableRowView.isNeedSetupShadow = false
        }

        return audioTableRowView
    }
}
