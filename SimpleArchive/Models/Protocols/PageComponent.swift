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
    var componentDetail: DetailType { get }

    @discardableResult
    func store<ComponentEntityType>(in ctx: NSManagedObjectContext, parentPage: MemoPageEntity)
        -> ComponentEntityType where ComponentEntityType: MemoComponentEntity

    func getCollectionViewComponentCell(
        _ collectionView: UICollectionView,
        _ indexPath: IndexPath,
        subject: PassthroughSubject<MemoPageViewInput, Never>
    ) -> UICollectionViewCell
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
