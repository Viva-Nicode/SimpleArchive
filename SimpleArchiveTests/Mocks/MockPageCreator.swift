@testable import SimpleArchive

final class MockPageCreator: Mock, PageCreatorType {
    
    enum Action: Equatable {
        case createFile
        case setFirstComponentType
    }

    var actions = MockActions<Action>(expected: [])
    var createFileResult: MemoPageModel!

    func createFile(itemName: String, parentDirectory: MemoDirectoryModel?) -> any StorageItem {
        register(.createFile)
        return createFileResult
    }

    func createFile(itemName: String, parentDirectory: MemoDirectoryModel?, singleComponentType: ComponentType)
        -> any StorageItem
    {
        register(.createFile)
        return createFileResult
    }

    func setFirstComponentType(type: ComponentType) {
        register(.setFirstComponentType)
    }

}
