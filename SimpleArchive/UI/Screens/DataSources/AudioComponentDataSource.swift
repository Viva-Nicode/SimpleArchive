import UIKit

final class AudioComponentDataSource: NSObject, UITableViewDataSource {
    private var audioPageComponent: AudioComponent
    private var activeTrackVisualizerData = AudioComponentSoundPlayer.shared.activeTrackVisualizerData
    var searchingKeywoard = ""

    init(audioPageComponent: AudioComponent) {
        self.audioPageComponent = audioPageComponent
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return audioPageComponent.componentContents.tracks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let track = audioPageComponent.componentContents.tracks[indexPath.row]

        let audioTableRowView =
            tableView.dequeueReusableCell(
                withIdentifier: AudioTableRowView.reuseIdentifier,
                for: indexPath) as! AudioTableRowView

        let isVisible = shouldDisplayRow(indexPath: indexPath)
        audioTableRowView.configure(audioTrack: track, isSearchingResult: isVisible)

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

	// MARK: - Searching -
    func shouldDisplayRow(indexPath: IndexPath) -> Bool {
        let track = audioPageComponent.componentContents.tracks[indexPath.row]
        if searchingKeywoard.isEmpty {
            return true
        } else {
            let score1 = matchScore(track.title, keyword: searchingKeywoard)
            let score2 = matchScore(track.artist, keyword: searchingKeywoard)
            let finalScore = max(score1, score2)
            let isMatch = finalScore > 30
            return isMatch
        }
    }

    func numberOfVisibleRows() -> Int? {
        searchingKeywoard.isEmpty
            ? nil
            : {
                audioPageComponent
                    .componentContents
                    .tracks
                    .enumerated()
                    .map { IndexPath(row: $0.offset, section: 0) }
                    .filter { shouldDisplayRow(indexPath: $0) }
                    .count
            }()
    }

    private func matchScore(_ text: String, keyword: String) -> Int {
        guard !keyword.isEmpty else { return 0 }

        func normalize(_ text: String) -> String {
            return
                text
                .lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
                .replacingOccurrences(of: " ", with: "")
        }

        let text = normalize(text)
        let keyword = normalize(keyword)

        var score = 0

        if text.contains(keyword) {
            score += 100
        }

        let pattern =
            keyword
            .map { NSRegularExpression.escapedPattern(for: String($0)) }
            .joined(separator: ".*")

        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(text.startIndex..., in: text)
            if regex.firstMatch(in: text, options: [], range: range) != nil {
                score += 50
            }
        }

        let matchedCount = keyword.filter { text.contains(String($0)) }.count
        score += matchedCount * 5

        let lengthDiff = abs(text.count - keyword.count)
        score -= lengthDiff

        return max(score, 0)
    }
}
