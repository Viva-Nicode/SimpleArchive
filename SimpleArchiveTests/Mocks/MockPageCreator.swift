@testable import SimpleArchive

class MockPageCreator: Mock, FileCreatorType {

    enum Action: Equatable {
        case createFile
        case setFirstComponentType
    }

    var actions = MockActions<Action>(expected: [])
    var createFileResult: MemoPageModel!

    func createFile(itemName: String, parentDirectory: MemoDirectoryModel?) -> some StorageItem {
        register(.createFile)
        return createFileResult
    }

    func setFirstComponentType(type: ComponentType) {
        register(.setFirstComponentType)
    }
}
