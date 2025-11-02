import Combine
import CoreData
import Foundation
import UIKit

protocol PageComponent: AnyObject, Identifiable, Codable {

    associatedtype DetailType: Codable

    var id: UUID { get }
    var creationDate: Date { get set }
    var title: String { get set }
    var type: ComponentType { get }
    var detail: DetailType { get set }
    var renderingOrder: Int { get set }
    var isMinimumHeight: Bool { get set }
    var persistenceState: PersistentState { get set }
    var componentDetail: DetailType { get }

    func updatePersistenceState(to state: PersistentState)
    func currentIfUnsaved() -> Self?

    @discardableResult
    func store<ComponentEntityType>(in ctx: NSManagedObjectContext, parentPage: MemoPageEntity)
        -> ComponentEntityType where ComponentEntityType: MemoComponentEntity

    func getCollectionViewComponentCell(
        _ collectionView: UICollectionView,
        _ indexPath: IndexPath,
        isReadOnly: Bool,
        subject: PassthroughSubject<MemoPageViewInput, Never>
    ) -> UICollectionViewCell
}

extension PageComponent {

    func updatePersistenceState(to state: PersistentState) {
        self.persistenceState = state
    }

    func currentIfUnsaved() -> Self? {
        switch self.persistenceState {
            case .unsaved:
                return self

            case .synced:
                return nil
        }
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
                "TextMemo"

            case .table:
                "TableMemo"

            case .audio:
                "AudioMemo"
        }
    }

    var getSymbolSystemName: String {
        switch self {
            case .text:
                "note.text.badge.plus"

            case .table:
                "tablecells"

            case .audio:
                "music.note.list"
        }
    }
}

enum PersistentState: Codable, Equatable {
    case unsaved(isMustToStoreSnapshot: Bool)
    case synced
}
