import CoreData

final class CoreDataPageComponentPersistenceCreator: PageComponentPersistenceCreatorType {
    let context: NSManagedObjectContext
    let parentPage: MemoPageEntity

    init(context: NSManagedObjectContext, parentPage: MemoPageEntity) {
        self.context = context
        self.parentPage = parentPage
    }

    func persistTextEditorComponent(textComponent: TextEditorComponent) {
        let textEditorComponentEntity = TextEditorComponentEntity(context: context)

        textEditorComponentEntity.id = textComponent.id
        textEditorComponentEntity.creationDate = textComponent.creationDate
        textEditorComponentEntity.renderingOrder = textComponent.renderingOrder
        textEditorComponentEntity.type = textComponent.type.rawValue
        textEditorComponentEntity.isMinimumHeight = textComponent.isMinimumHeight
        textEditorComponentEntity.title = textComponent.title
        textEditorComponentEntity.contents = textComponent.componentContents
        textEditorComponentEntity.snapshots = []

        textComponent.snapshots.forEach { snapshot in
            let persistence = CoreDataComponentSnapshotPersistenceCreator(
                context: context, parentComponent: textEditorComponentEntity)
            snapshot.persistToPersistentStorage(using: persistence)
        }

        parentPage.addToComponents(textEditorComponentEntity)
    }

    func persistTableComponent(tableComponent: TableComponent) {
        let tableComponentEntity = TableComponentEntity(context: context)

        tableComponentEntity.id = tableComponent.id
        tableComponentEntity.creationDate = tableComponent.creationDate
        tableComponentEntity.renderingOrder = tableComponent.renderingOrder
        tableComponentEntity.type = tableComponent.type.rawValue
        tableComponentEntity.isMinimumHeight = tableComponent.isMinimumHeight
        tableComponentEntity.title = tableComponent.title
        tableComponentEntity.sortBy = tableComponent.componentContents.sortBy.rawValue

        let orderedColumns = tableComponentEntity.mutableOrderedSetValue(forKey: "columns")

        for col in tableComponent.componentContents.columns {
            let colEntity = TableComponentColumnEntity(context: context)
            colEntity.id = col.id
            colEntity.title = col.title
            colEntity.tableComponent = tableComponentEntity

            orderedColumns.add(colEntity)
        }

        let orderedRows = tableComponentEntity.mutableOrderedSetValue(forKey: "rows")

        for row in tableComponent.componentContents.rows {
            let rowEntity = TableComponentRowEntity(context: context)
            rowEntity.id = row.id
            rowEntity.createdAt = row.createdAt
            rowEntity.modifiedAt = row.modifiedAt
            rowEntity.tableComponent = tableComponentEntity

            orderedRows.add(rowEntity)
        }

        for case let columnEntity as TableComponentColumnEntity in tableComponentEntity.columns {
            for case let rowEntity as TableComponentRowEntity in tableComponentEntity.rows {
                let cellEntity = TableComponentCellEntity(context: context)
                cellEntity.value = tableComponent.componentContents.cells[rowEntity.id]?[columnEntity.id] ?? ""

                cellEntity.row = rowEntity
                cellEntity.column = columnEntity

                rowEntity.addToCells(cellEntity)
                columnEntity.addToCells(cellEntity)
            }
        }

        tableComponentEntity.snapshots = []
        tableComponent.snapshots.forEach { snapshot in
            let persistence = CoreDataComponentSnapshotPersistenceCreator(
                context: context, parentComponent: tableComponentEntity)
            snapshot.persistToPersistentStorage(using: persistence)
        }

        parentPage.addToComponents(tableComponentEntity)
    }

    func persistAudioComponent(audioComponent: AudioComponent) {
        let audioComponentEntity = AudioComponentEntity(context: context)
        audioComponentEntity.id = audioComponent.id
        audioComponentEntity.creationDate = audioComponent.creationDate
        audioComponentEntity.renderingOrder = audioComponent.renderingOrder
        audioComponentEntity.type = audioComponent.type.rawValue
        audioComponentEntity.isMinimumHeight = audioComponent.isMinimumHeight
        audioComponentEntity.title = audioComponent.title
        audioComponentEntity.sortBy = audioComponent.componentContents.sortBy.rawValue

        let audioEntities = audioComponentEntity.mutableOrderedSetValue(forKey: "audios")

        for audioTrack in audioComponent.componentContents.tracks {
            let audioEntity = AudioComponentTrackEntity(context: context)

            audioEntity.id = audioTrack.id
            audioEntity.title = audioTrack.title
            audioEntity.artist = audioTrack.artist
            audioEntity.createData = audioTrack.createData
            audioEntity.fileExtension = audioTrack.fileExtension.rawValue
            audioEntity.thumbnail = audioTrack.thumbnail
            audioEntity.lyrics = audioTrack.lyrics
            audioEntity.audioComponent = audioComponentEntity

            audioEntities.add(audioEntity)
        }
        parentPage.addToComponents(audioComponentEntity)
    }
}
