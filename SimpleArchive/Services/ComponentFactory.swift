import CoreData

protocol ComponentFactoryType {
    func setCreator(creator: any ComponentCreatorType)
    func createComponent() -> any PageComponent
}

final class ComponentFactory: ComponentFactoryType {

    private var creator: any ComponentCreatorType

    init(creator: any ComponentCreatorType) {
        self.creator = creator
    }

    func setCreator(creator: any ComponentCreatorType) {
        self.creator = creator
    }

    func createComponent() -> any PageComponent {
        creator.createEmptyComponent()
    }
}
