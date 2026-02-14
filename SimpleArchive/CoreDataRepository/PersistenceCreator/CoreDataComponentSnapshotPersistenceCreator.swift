import CoreData

final class CoreDataComponentSnapshotPersistenceCreator: ComponentSnapshotPersistenceCreatorType {
    private let parentComponent: MemoComponentEntity

    init(parentComponent: MemoComponentEntity) {
        self.parentComponent = parentComponent
    }

    func persistTextEditorComponentSnapshot(snapshot: TextEditorComponentSnapshot) {
        guard let context = parentComponent.managedObjectContext else { return }
        guard let textEditorComponentEntity = parentComponent as? TextEditorComponentEntity else { return }

        let textEditorComponentSnapshotEntity = TextEditorComponentSnapshotEntity(context: context)
        textEditorComponentSnapshotEntity.snapshotID = snapshot.snapshotID
        textEditorComponentSnapshotEntity.makingDate = snapshot.makingDate
        textEditorComponentSnapshotEntity.contents = snapshot.snapshotContents
        textEditorComponentSnapshotEntity.snapShotDescription = snapshot.description
        textEditorComponentSnapshotEntity.saveMode = snapshot.saveMode.rawValue
        textEditorComponentSnapshotEntity.modificationHistory = snapshot.modificationHistory.jsonString

        textEditorComponentEntity.addToSnapshots(textEditorComponentSnapshotEntity)
        textEditorComponentSnapshotEntity.component = textEditorComponentEntity
    }

    func persistTableComponentSnapshot(snapshot: TableComponentSnapshot) {
        guard let context = parentComponent.managedObjectContext else { return }
        guard let tableComponentEntity = parentComponent as? TableComponentEntity else { return }

        let tableComponentSnapshotEntity = TableComponentSnapshotEntity(context: context)
        tableComponentSnapshotEntity.snapshotID = snapshot.snapshotID
        tableComponentSnapshotEntity.makingDate = snapshot.makingDate
		tableComponentSnapshotEntity.contents = TableComponentSnapshotEntity.persistTableComponentSnapshotContents(
            contents: snapshot.snapshotContents)
        tableComponentSnapshotEntity.snapShotDescription = snapshot.description
        tableComponentSnapshotEntity.saveMode = snapshot.saveMode.rawValue
        tableComponentSnapshotEntity.modificationHistory = snapshot.modificationHistory.jsonString

        tableComponentEntity.addToSnapshots(tableComponentSnapshotEntity)
        tableComponentSnapshotEntity.component = tableComponentEntity
    }
}
