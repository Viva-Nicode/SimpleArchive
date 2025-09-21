@testable import SimpleArchive

class MockDirectoryCreator: Mock, FileCreatorType {

    enum Action: Equatable {
        case createFile
    }

    var actions = MockActions<Action>(expected: [])
    var createFileResult: MemoDirectoryModel!

    func createFile(itemName: String, parentDirectory: MemoDirectoryModel?) -> some StorageItem {
        register(.createFile)
        return createFileResult
    }
}
