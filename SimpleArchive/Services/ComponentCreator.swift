import CoreData
import Foundation

protocol ComponentCreatorType {
    associatedtype CreatingComponentType: PageComponent
    func createEmptyComponent() -> CreatingComponentType
}

struct TextEditorComponentCreator: ComponentCreatorType {
    typealias CreatingComponentType = TextEditorComponent
    func createEmptyComponent() -> CreatingComponentType { TextEditorComponent() }
}

struct TableComponentCreator: ComponentCreatorType {
    typealias CreatingComponentType = TableComponent
    func createEmptyComponent() -> TableComponent { TableComponent() }
}
