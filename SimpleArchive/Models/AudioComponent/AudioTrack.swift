import CSFBAudioEngine
import Foundation

enum AudioTrackExtension: String, Codable {
    case mp3 = "mp3"
    case m4a = "m4a"
}

struct AudioTrack: Codable, Identifiable {
    var id: UUID
    var title: String
    var artist: String
    var thumbnail: Data
    var lyrics: String
    var fileExtension: AudioTrackExtension
    let createData: Date

    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        thumbnail: Data,
        lyrics: String,
        fileExtension: AudioTrackExtension,
        createData: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.thumbnail = thumbnail
        self.lyrics = lyrics
        self.fileExtension = fileExtension
        self.createData = createData
    }
}
