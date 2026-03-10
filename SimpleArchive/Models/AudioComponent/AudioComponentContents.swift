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
}
