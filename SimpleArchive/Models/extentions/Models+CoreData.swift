import CoreData

extension MemoDirectoryModel {
    func store(in ctx: NSManagedObjectContext, parentDirectory: MemoDirectoryEntity? = nil) {
        let directoryEntity = MemoDirectoryEntity(context: ctx)
        directoryEntity.id = self.id
        directoryEntity.name = self.name
        directoryEntity.sortBy = self.getSortBy().rawValue
        directoryEntity.creationDate = self.creationDate
        directoryEntity.childDirectories = []
        directoryEntity.pages = []
        parentDirectory?.addToChildDirectories(directoryEntity)

        self.getChildItems().forEach { $0.store(in: ctx, parentDirectory: directoryEntity) }
    }
}

extension MemoPageModel {
    func store(in ctx: NSManagedObjectContext, parentDirectory: MemoDirectoryEntity? = nil) {

        let memoPageEntity = MemoPageEntity(context: ctx)
        memoPageEntity.id = self.id
        memoPageEntity.name = self.name
        memoPageEntity.creationDate = self.creationDate
        memoPageEntity.isSingleComponentPage = self.isSingleComponentPage
        memoPageEntity.components = []

        self.getComponents.forEach { $0.storePageComponentEntity(in: ctx, parentPage: memoPageEntity) }
        parentDirectory?.addToPages(memoPageEntity)
    }
}

extension TextEditorComponent {
    func storePageComponentEntity(in ctx: NSManagedObjectContext, parentPage: MemoPageEntity) {
        let textEditorComponentEntity = TextEditorComponentEntity(context: ctx)

        textEditorComponentEntity.id = self.id
        textEditorComponentEntity.creationDate = self.creationDate
        textEditorComponentEntity.renderingOrder = self.renderingOrder
        textEditorComponentEntity.type = self.type.rawValue
        textEditorComponentEntity.isMinimumHeight = self.isMinimumHeight
        textEditorComponentEntity.title = self.title
        textEditorComponentEntity.contents = self.componentContents
        textEditorComponentEntity.snapshots = []

        self.snapshots.forEach { $0.store(in: ctx, entity: textEditorComponentEntity) }

        parentPage.addToComponents(textEditorComponentEntity)
    }
}

extension TableComponent {
    func storePageComponentEntity(in ctx: NSManagedObjectContext, parentPage: MemoPageEntity) {
        let tableComponentEntity = TableComponentEntity(context: ctx)
        tableComponentEntity.id = self.id
        tableComponentEntity.creationDate = self.creationDate
        tableComponentEntity.renderingOrder = self.renderingOrder
        tableComponentEntity.type = self.type.rawValue
        tableComponentEntity.isMinimumHeight = self.isMinimumHeight
        tableComponentEntity.title = self.title

        self.componentContents.storeTableComponentContent(for: tableComponentEntity, in: ctx)

        tableComponentEntity.snapshots = []
        self.snapshots.forEach { $0.store(in: ctx, entity: tableComponentEntity) }

        parentPage.addToComponents(tableComponentEntity)
    }
}

extension AudioComponent {
    func storePageComponentEntity(in ctx: NSManagedObjectContext, parentPage: MemoPageEntity) {
        let audioComponentEntity = AudioComponentEntity(context: ctx)
        audioComponentEntity.id = self.id
        audioComponentEntity.creationDate = self.creationDate
        audioComponentEntity.renderingOrder = self.renderingOrder
        audioComponentEntity.type = self.type.rawValue
        audioComponentEntity.isMinimumHeight = self.isMinimumHeight
        audioComponentEntity.title = self.title

        componentContents.storeAudioComponentContent(for: audioComponentEntity, in: ctx)
        parentPage.addToComponents(audioComponentEntity)
    }
}

extension TextEditorComponentSnapshot {
    func store(in ctx: NSManagedObjectContext, entity: MemoComponentEntity) {
        guard let textEditorComponentEntity = entity as? TextEditorComponentEntity else { return }

        let textEditorComponentSnapshotEntity = TextEditorComponentSnapshotEntity(context: ctx)
        textEditorComponentSnapshotEntity.snapshotID = self.snapshotID
        textEditorComponentSnapshotEntity.makingDate = self.makingDate
        textEditorComponentSnapshotEntity.contents = self.contents
        textEditorComponentSnapshotEntity.snapShotDescription = self.description
        textEditorComponentSnapshotEntity.saveMode = self.saveMode.rawValue

        textEditorComponentEntity.addToSnapshots(textEditorComponentSnapshotEntity)
        textEditorComponentSnapshotEntity.component = textEditorComponentEntity
    }
}

extension TableComponentSnapshot {
    func store(in ctx: NSManagedObjectContext, entity: MemoComponentEntity) {
        guard let tableComponentEntity = entity as? TableComponentEntity else { return }

        let tableComponentSnapshotEntity = TableComponentSnapshotEntity(context: ctx)
        tableComponentSnapshotEntity.snapshotID = self.snapshotID
        tableComponentSnapshotEntity.makingDate = self.makingDate
        tableComponentSnapshotEntity.contents = self.contents.jsonString
        tableComponentSnapshotEntity.snapShotDescription = self.description
        tableComponentSnapshotEntity.saveMode = self.saveMode.rawValue

        tableComponentEntity.addToSnapshots(tableComponentSnapshotEntity)
        tableComponentSnapshotEntity.component = tableComponentEntity
    }
}
