import Foundation

protocol FileCreatorType {
    associatedtype ProductType: StorageItem
    func createFile(itemName: String, parentDirectory: MemoDirectoryModel?) -> ProductType

    func setFirstComponentType(type: ComponentType)
}

extension FileCreatorType {
    func setFirstComponentType(type: ComponentType) {}
}

struct DirectoryCreator: FileCreatorType {
    func createFile(itemName: String, parentDirectory: MemoDirectoryModel?) -> some StorageItem {
        MemoDirectoryModel(name: itemName, parentDirectory: parentDirectory)
    }
}

struct PageCreator: FileCreatorType {

    private let componentFactory: any ComponentFactoryType

    init(componentFactory: any ComponentFactoryType) {
        self.componentFactory = componentFactory
    }

    func createFile(itemName: String, parentDirectory: MemoDirectoryModel?, singleComponentType: ComponentType)
        -> some StorageItem
    {
        let component = componentFactory.createComponent()
        let page = MemoPageModel(name: itemName, isSingleComponentPage: true, parentDirectory: parentDirectory)
        component.title = itemName

        page.appendChildComponent(component: component)
        return page
    }

    func createFile(itemName: String, parentDirectory: MemoDirectoryModel?) -> some StorageItem {

        let component = componentFactory.createComponent()
        let page = MemoPageModel(name: itemName, parentDirectory: parentDirectory)

        page.appendChildComponent(component: component)
        return page
    }

    func setFirstComponentType(type: ComponentType) {
        self.componentFactory.setCreator(creator: type.getComponentCreator())
    }
}
