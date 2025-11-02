import CoreData
import Foundation

@objc(AudioComponentEntity)
public class AudioComponentEntity: MemoComponentEntity {
    override func convertToModel() -> any PageComponent {
        let audioComponent = AudioComponent(
            id: self.id,
            renderingOrder: self.renderingOrder,
            isMinimumHeight: self.isMinimumHeight,
            creationDate: self.creationDate,
            title: self.title,
            detail: AudioComponentContent(jsonString: self.detail)!,
            persistenceState: .synced)

        return audioComponent
    }

    override func setDetail<T: Codable>(detail: T) {
        self.detail = (detail as! AudioComponentContent).jsonString
    }
}
