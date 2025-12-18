import UIKit

struct AudioWaveformData: Codable, Equatable {
    var sampleDataCount: Int
    var sampleRate: Double
    var waveformData: [[Float]]
}

class AudioComponentDataSource: NSObject, UITableViewDataSource {

    var tracks: [AudioTrack]
    var sortBy: AudioTrackSortBy
    var nowPlayingAudioIndex: Int?
    var nowPlayingURL: URL?
    var isPlaying: Bool?
    var audioVisualizerData: AudioWaveformData?
    var getProgress: (() -> Double)?

    init(tracks: [AudioTrack], sortBy: AudioTrackSortBy) {
        self.tracks = tracks
        self.sortBy = sortBy
    }

    deinit { print("deinit AudioComponentDataSource") }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { tracks.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let track = tracks[indexPath.row]
        let audioTableRowView =
            tableView.dequeueReusableCell(
                withIdentifier: AudioTableRowView.reuseIdentifier,
                for: indexPath) as! AudioTableRowView

        audioTableRowView.configure(audioTrack: track)

        if let audioVisualizerData, let progress = getProgress?(), indexPath.row == nowPlayingAudioIndex {
            DispatchQueue.main.async {
                audioTableRowView.audioVisualizer.activateAudioVisualizer(
                    samplesCount: audioVisualizerData.sampleDataCount,
                    scaledSamples: audioVisualizerData.waveformData,
                    sampleRate: audioVisualizerData.sampleRate)
                audioTableRowView.audioVisualizer.seekVisuzlization(rate: progress)
                if self.isPlaying == false {
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
