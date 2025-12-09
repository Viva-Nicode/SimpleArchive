import AVFAudio
import Foundation
import UIKit

final class AudioComponent: NSObject, Codable, PageComponent {

    var id: UUID
    var creationDate: Date
    var title: String
    var type: ComponentType { .audio }
    var renderingOrder: Int
    var isMinimumHeight: Bool
    var componentContents: AudioComponentContents

    init(
        id: UUID = UUID(),
        renderingOrder: Int = 0,
        isMinimumHeight: Bool = false,
        creationDate: Date = Date(),
        title: String = "AudioMemo",
        contents: ContentType = AudioComponentContents()
    ) {
        self.id = id
        self.renderingOrder = renderingOrder
        self.isMinimumHeight = isMinimumHeight
        self.creationDate = creationDate
        self.title = title
        self.componentContents = contents
    }

    enum CodingKeys: String, CodingKey {
        case id, creationDate, title, renderingOrder, isMinimumHeight, componentContents
    }

    deinit { print("deinit AudioComponentModel : \(title)") }

    var trackNames: [String] {
        componentContents.tracks.map { "\($0.id).\($0.fileExtension)" }
    }

    func addAudios(audiotracks: [AudioTrack]) -> [Int] {
        componentContents.addAudios(audiotracks: audiotracks)
    }
}
