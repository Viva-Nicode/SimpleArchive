import Combine
import CoreData
import Foundation
import UIKit

protocol PageComponentPersistenceCreatorType {
    func persistTextEditorComponent(textComponent: TextEditorComponent)
    func persistTableComponent(tableComponent: TableComponent)
    func persistAudioComponent(audioComponent: AudioComponent)
}

// 컴포넌트를 어떤 형태의 뷰로 변환해주는 책임.
// 아래 프로토콜은 컴포넌트들은 어떤 형태의 뷰로 표시될 수있어야 한다는 비즈니스 룰을의미하기도 함.

protocol PageComponentViewFactoryType {
    associatedtype ViewType
    func makeComponentView(from component: any PageComponent) -> ViewType
}

protocol PageComponent: AnyObject, Identifiable, Codable {

    associatedtype ContentType: Codable

    var id: UUID { get }
    var creationDate: Date { get set }
    var title: String { get set }
    var type: ComponentType { get }
    var componentContents: ContentType { get set }
    var renderingOrder: Int { get set }
    var isMinimumHeight: Bool { get set }

    func persistToPersistentStorage(using persistence: PageComponentPersistenceCreatorType)
    func makeComponentView<Factory: PageComponentViewFactoryType>(using factory: Factory) -> Factory.ViewType
}
// 컴포넌트가 어떤 형태의 시각적으로 화면에 표시될 수있는 뷰로 변환되어야 하는것도 비즈니스 룰이라고 판단.
// 따라서 컴포넌트를 뷰로 바꾸는 팩토리 프로토콜을 만들고, 팩토리의 구체타입에따라 그에 맞는 뷰들을 생성해낼수 있게함.
// 재네릭 타입 ViewType을 사용함으로써 UICollectionViewCell이외에도 다른 뷰타입에 대응가능.
// PageComponentViewFactoryType의 실제 구현체는 Framework layer에서 구현.

extension PageComponent {
    func makeComponentView<Factory: PageComponentViewFactoryType>(using factory: Factory) -> Factory.ViewType {
        factory.makeComponentView(from: self)
    }
}

enum ComponentType: String, Codable, CaseIterable {
    case text = "TEXT"
    case table = "TABLE"
    case audio = "AUDIO"

    func getComponentCreator() -> any ComponentCreatorType {
        switch self {
            case .text:
                TextEditorComponentCreator()

            case .table:
                TableComponentCreator()

            case .audio:
                AudioComponentCreator()
        }
    }

    var getTitle: String {
        switch self {
            case .text:
                "Text"

            case .table:
                "Table"

            case .audio:
                "Audio"
        }
    }

    var getSymbolSystemName: String {
        switch self {
            case .text:
                "note.text"

            case .table:
                "tablecells"

            case .audio:
                "music.note.list"
        }
    }
}
