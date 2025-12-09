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
            contents: AudioComponentContents(jsonString: self.detail)!)

        return audioComponent
    }
}
