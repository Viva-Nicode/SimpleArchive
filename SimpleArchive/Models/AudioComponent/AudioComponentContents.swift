import CoreData
import Foundation

enum AudioTrackSortBy: String, Codable {
    case name = "name"
    case createDate = "createDate"
    case manual = "manual"
}

struct AudioComponentContents: Codable {

    var tracks: [AudioTrack]
    var sortBy: AudioTrackSortBy

    init() {
        self.tracks = []
        self.sortBy = .manual
    }

    mutating func addAudios(audiotracks: [AudioTrack]) -> [Int] {
        self.tracks.append(contentsOf: audiotracks)

        switch sortBy {
            case .name:
                self.tracks.sort(by: { $0.title < $1.title })

            case .createDate:
                self.tracks.sort(by: { $0.createData > $1.createData })

            case .manual:
                break
        }

        var appendedIndex: [Int] = []

        for track in audiotracks {
            if let idx = self.tracks.firstIndex(where: { $0.id == track.id }) {
                appendedIndex.append(idx)
            }
        }
        return appendedIndex
    }
}
