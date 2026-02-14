import CoreData

protocol ComponentSnapshotPersistenceCreatorType {
    func persistTextEditorComponentSnapshot(snapshot: TextEditorComponentSnapshot)
    func persistTableComponentSnapshot(snapshot: TableComponentSnapshot)
}

protocol PageComponentSnapshotViewFactoryType {
    associatedtype ViewType
    func makeComponentSnapshotView(from snapshot: any ComponentSnapshotType) -> ViewType
}

protocol ComponentSnapshotType: Codable {
    associatedtype ComponentType: PageComponent

    var snapshotID: UUID { get set }
    var makingDate: Date { get set }
    var description: String { get set }
    var saveMode: SnapshotSaveMode { get set }
    var snapshotContents: ComponentType.ContentType { get set }

    func revert(component: ComponentType)

    func getSnapshotMetaData() -> SnapshotMetaData
    func persistToPersistentStorage(using persistence: ComponentSnapshotPersistenceCreatorType)

    func isEqual(to other: any ComponentSnapshotType) -> Bool
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
	case revert = "revert"
}

struct SnapshotMetaData: Equatable {
    var savemode: String
    var makingDate: String
    var snapshotDescription: String
}
