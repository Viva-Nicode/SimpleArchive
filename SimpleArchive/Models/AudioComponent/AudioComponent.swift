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
    var persistenceState: PersistentState
    var componentDetail: AudioComponentContent { detail }
    var detail: AudioComponentContent
    
    init(
        id: UUID = UUID(),
        renderingOrder: Int = 0,
        isMinimumHeight: Bool = false,
        creationDate: Date = Date(),
        title: String = "AudioMemo",
        detail: DetailType = AudioComponentContent(),
        persistenceState: PersistentState = .synced,
    ) {
        self.id = id
        self.renderingOrder = renderingOrder
        self.isMinimumHeight = isMinimumHeight
        self.creationDate = creationDate
        self.title = title
        self.detail = detail
        self.persistenceState = persistenceState
    }
    
    deinit { print("deinit AudioComponentModel : \(title)") }
    
    func addAudios(audiotracks: [AudioTrack]) -> [Int] {
        persistenceState = .unsaved(isMustToStoreSnapshot: false)
        return detail.addAudios(audiotracks: audiotracks)
    }
    
    var trackNames: [String] {
        detail.tracks.map { "\($0.id).\($0.fileExtension)" }
    }
}
