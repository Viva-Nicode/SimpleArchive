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

extension AudioComponentContents {
    func storeAudioComponentContent(for audioComponentEntity: AudioComponentEntity, in ctx: NSManagedObjectContext) {
        audioComponentEntity.sortBy = sortBy.rawValue

        let audioEntities = audioComponentEntity.mutableOrderedSetValue(forKey: "audios")

        for audioTrack in tracks {
            let audioEntity = AudioComponentTrackEntity(context: ctx)

            audioEntity.id = audioTrack.id
            audioEntity.title = audioTrack.title
            audioEntity.artist = audioTrack.artist
            audioEntity.createData = audioTrack.createData
            audioEntity.fileExtension = audioTrack.fileExtension.rawValue
            audioEntity.thumbnail = audioTrack.thumbnail
            audioEntity.lyrics = audioTrack.lyrics
            audioEntity.audioComponent = audioComponentEntity

            audioEntities.add(audioEntity)
        }
    }

    init(entity: AudioComponentEntity) {
        self.sortBy = .init(rawValue: entity.sortBy)!

        let audioEntities = entity.mutableOrderedSetValue(forKey: "audios")
        let audioList = audioEntities.array as! [AudioComponentTrackEntity]

        self.tracks = audioList.map {
            AudioTrack(
                id: $0.id,
                title: $0.title,
                artist: $0.artist,
                thumbnail: $0.thumbnail,
                lyrics: $0.lyrics,
                fileExtension: .init(rawValue: $0.fileExtension)!,
                createData: $0.createData)
        }
    }
}
