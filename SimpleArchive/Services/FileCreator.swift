import Foundation

protocol FileCreatorType {
    func createFile(itemName: String, parentDirectory: MemoDirectoryModel?) -> any StorageItem
}

protocol PageCreatorType: FileCreatorType {
    func createFile(
        itemName: String,
        parentDirectory: MemoDirectoryModel?,
        singleComponentType: ComponentType
    ) -> any StorageItem
    func setFirstComponentType(type: ComponentType)
}

struct PageCreator: PageCreatorType {

    private let componentFactory: any ComponentFactoryType

    init(componentFactory: any ComponentFactoryType) {
        self.componentFactory = componentFactory
    }

    func createFile(itemName: String, parentDirectory: MemoDirectoryModel?) -> any StorageItem {
        let component = componentFactory.createComponent()
        let page = MemoPageModel(name: itemName, parentDirectory: parentDirectory)

        page.appendChildComponent(component: component)
        return page
    }

    func createFile(itemName: String, parentDirectory: MemoDirectoryModel?, singleComponentType: ComponentType)
        -> any StorageItem
    {
        let component = componentFactory.createComponent()
        let page = MemoPageModel(name: itemName, isSingleComponentPage: true, parentDirectory: parentDirectory)
        component.title = itemName

        page.appendChildComponent(component: component)
        return page
    }

    func setFirstComponentType(type: ComponentType) {
        self.componentFactory.setCreator(creator: type.getComponentCreator())
    }
}

struct DirectoryCreator: FileCreatorType {
    func createFile(itemName: String, parentDirectory: MemoDirectoryModel?) -> any StorageItem {
        MemoDirectoryModel(name: itemName, parentDirectory: parentDirectory)
    }
}
