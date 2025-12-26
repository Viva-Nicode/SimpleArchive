import CoreData
import Foundation

protocol ComponentCreatorType {
    associatedtype CreatingComponentType: PageComponent
    func createEmptyComponent() -> CreatingComponentType
}

struct TextEditorComponentCreator: ComponentCreatorType {
    func createEmptyComponent() -> TextEditorComponent { TextEditorComponent() }
}

struct TableComponentCreator: ComponentCreatorType {
    func createEmptyComponent() -> TableComponent { TableComponent() }
}

struct AudioComponentCreator: ComponentCreatorType {
    func createEmptyComponent() -> AudioComponent { AudioComponent() }
}
