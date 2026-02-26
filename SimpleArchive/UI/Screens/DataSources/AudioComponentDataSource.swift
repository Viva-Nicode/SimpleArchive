import UIKit

final class AudioComponentDataSource: NSObject, UITableViewDataSource {
    private var audioPageComponent: AudioComponent
    private var activeTrackVisualizerData = AudioComponentSoundPlayer.shared.activeTrackVisualizerData

    init(audioPageComponent: AudioComponent) {
        self.audioPageComponent = audioPageComponent
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        audioPageComponent.componentContents.tracks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let track = audioPageComponent.componentContents.tracks[indexPath.row]

        let audioTableRowView =
            tableView.dequeueReusableCell(
                withIdentifier: AudioTableRowView.reuseIdentifier,
                for: indexPath) as! AudioTableRowView

        audioTableRowView.configure(audioTrack: track)

        activeTrackVisualizerData.playbackVisualizer(
            componentID: audioPageComponent.id,
            trackID: track.id,
            audioVisualizer: audioTableRowView.audioVisualizer)

        if audioTableRowView.isNeedSetupShadow {
            audioTableRowView.setupShadow()
            audioTableRowView.isNeedSetupShadow = false
        }

        return audioTableRowView
    }
}
