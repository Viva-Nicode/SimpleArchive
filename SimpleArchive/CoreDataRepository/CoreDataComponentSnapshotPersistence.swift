import CoreData

final class CoreDataComponentSnapshotPersistenceCreator: ComponentSnapshotPersistenceCreatorType {
    let context: NSManagedObjectContext
    let parentComponent: MemoComponentEntity

    init(context: NSManagedObjectContext, parentComponent: MemoComponentEntity) {
        self.context = context
        self.parentComponent = parentComponent
    }

    func persistTextEditorComponentSnapshot(snapshot: TextEditorComponentSnapshot) {
        guard let textEditorComponentEntity = parentComponent as? TextEditorComponentEntity else { return }

        let textEditorComponentSnapshotEntity = TextEditorComponentSnapshotEntity(context: context)
        textEditorComponentSnapshotEntity.snapshotID = snapshot.snapshotID
        textEditorComponentSnapshotEntity.makingDate = snapshot.makingDate
        textEditorComponentSnapshotEntity.contents = snapshot.contents
        textEditorComponentSnapshotEntity.snapShotDescription = snapshot.description
        textEditorComponentSnapshotEntity.saveMode = snapshot.saveMode.rawValue

        textEditorComponentEntity.addToSnapshots(textEditorComponentSnapshotEntity)
        textEditorComponentSnapshotEntity.component = textEditorComponentEntity
    }

    func persistTableComponentSnapshot(snapshot: TableComponentSnapshot) {
        guard let tableComponentEntity = parentComponent as? TableComponentEntity else { return }

        let tableComponentSnapshotEntity = TableComponentSnapshotEntity(context: context)
        tableComponentSnapshotEntity.snapshotID = snapshot.snapshotID
        tableComponentSnapshotEntity.makingDate = snapshot.makingDate
        tableComponentSnapshotEntity.contents = persistTableComponentSnapshotContents(contents: snapshot.contents)
        tableComponentSnapshotEntity.snapShotDescription = snapshot.description
        tableComponentSnapshotEntity.saveMode = snapshot.saveMode.rawValue

        tableComponentEntity.addToSnapshots(tableComponentSnapshotEntity)
        tableComponentSnapshotEntity.component = tableComponentEntity
    }

    private func persistTableComponentSnapshotContents(contents: TableComponentContents) -> String {
        guard let encoded = try? JSONEncoder().encode(contents),
            let jsonObject = try? JSONSerialization.jsonObject(with: encoded),
            let sortedData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.sortedKeys])
        else {
            return ""
        }

        return String(data: sortedData, encoding: .utf8) ?? ""
    }
}
