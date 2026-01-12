import CoreData

protocol ComponentSnapshotPersistenceCreatorType {
    func persistTextEditorComponentSnapshot(snapshot: TextEditorComponentSnapshot)
    func persistTableComponentSnapshot(snapshot: TableComponentSnapshot)
}

protocol ComponentSnapshotType: Codable {
    associatedtype ComponentType: PageComponent

    var snapshotID: UUID { get }
    var makingDate: Date { get }
    var description: String { get }
    var saveMode: SnapshotSaveMode { get }

    func revert(component: ComponentType)
    func getSnapshotMetaData() -> SnapshotMetaData

    func persistToPersistentStorage(using persistence: ComponentSnapshotPersistenceCreatorType)
}

extension ComponentSnapshotType {
    func getSnapshotMetaData() -> SnapshotMetaData {
        SnapshotMetaData(
            savemode: self.saveMode.rawValue,
            makingDate: self.makingDate.formattedDate,
            snapshotDescription: self.description.isEmpty ? "no comment" : self.description)
    }
}

enum SnapshotSaveMode: String, Codable {
    case automatic = "automatic"
    case manual = "manual"
}

struct SnapshotMetaData: Equatable {
    var savemode: String
    var makingDate: String
    var snapshotDescription: String
}
