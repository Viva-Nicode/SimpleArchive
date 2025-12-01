import CSFBAudioEngine
import Foundation

struct AudioTrack: Codable, Identifiable {
    var id: UUID
    var title: String
    var artist: String
    var thumbnail: Data
    var fileExtension: String
    let createData: Date

    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        thumbnail: Data,
        fileExtension: String,
        createData: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.thumbnail = thumbnail
        self.fileExtension = fileExtension
        self.createData = createData
    }
}
