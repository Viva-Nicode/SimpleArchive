import Foundation
import UIKit

struct AudioComponentContent: Codable {

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

    var jsonString: String {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted

            let jsonData = try encoder.encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            } else {
                return ""
            }
        } catch {
            return ""
        }
    }

    init?(jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else {
            return nil
        }
        do {
            let decoder = JSONDecoder()
            self = try decoder.decode(AudioComponentContent.self, from: data)
        } catch {
            return nil
        }
    }

    subscript(idx: Int?) -> AudioTrack? {
        guard let idx, (0..<tracks.count).contains(idx) else {
            return nil
        }
        let target = tracks[idx]
        return target
    }
}

enum AudioTrackSortBy: String, Codable {
    case name = "name"
    case createDate = "createDate"
    case manual = "manual"
}
