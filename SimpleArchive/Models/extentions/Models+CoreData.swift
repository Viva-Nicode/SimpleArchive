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

        self.getComponents.forEach { $0.store(in: ctx, parentPage: memoPageEntity) }
        parentDirectory?.addToPages(memoPageEntity)
    }
}

extension TextEditorComponent {
    func store<ComponentEntityType>(in ctx: NSManagedObjectContext, parentPage: MemoPageEntity)
        -> ComponentEntityType where ComponentEntityType: MemoComponentEntity
    {
        let textEditorComponentEntity = TextEditorComponentEntity(context: ctx)

        textEditorComponentEntity.id = self.id
        textEditorComponentEntity.creationDate = self.creationDate
        textEditorComponentEntity.renderingOrder = self.renderingOrder
        textEditorComponentEntity.type = self.type.rawValue
        textEditorComponentEntity.isMinimumHeight = self.isMinimumHeight
        textEditorComponentEntity.title = self.title
        textEditorComponentEntity.detail = self.detail
        textEditorComponentEntity.snapshots = []

        self.snapshots.forEach { $0.store(in: ctx, parentComponentId: self.id) }

        parentPage.addToComponents(textEditorComponentEntity)
        return textEditorComponentEntity as! ComponentEntityType
    }
}

extension TableComponent {
    func store<ComponentEntityType>(in ctx: NSManagedObjectContext, parentPage: MemoPageEntity)
        -> ComponentEntityType where ComponentEntityType: MemoComponentEntity
    {
        let tableComponentEntity = TableComponentEntity(context: ctx)
        tableComponentEntity.id = self.id
        tableComponentEntity.creationDate = self.creationDate
        tableComponentEntity.renderingOrder = self.renderingOrder
        tableComponentEntity.type = self.type.rawValue
        tableComponentEntity.isMinimumHeight = self.isMinimumHeight
        tableComponentEntity.title = self.title
        tableComponentEntity.detail = self.detail.jsonString
        tableComponentEntity.snapshots = []

        self.snapshots.forEach { $0.store(in: ctx, parentComponentId: self.id) }

        parentPage.addToComponents(tableComponentEntity)
        return tableComponentEntity as! ComponentEntityType
    }
}

extension AudioComponent {
    func store<ComponentEntityType>(in ctx: NSManagedObjectContext, parentPage: MemoPageEntity) -> ComponentEntityType
    where ComponentEntityType: MemoComponentEntity {
        let audioComponentEntity = AudioComponentEntity(context: ctx)
        audioComponentEntity.id = self.id
        audioComponentEntity.creationDate = self.creationDate
        audioComponentEntity.renderingOrder = self.renderingOrder
        audioComponentEntity.type = self.type.rawValue
        audioComponentEntity.isMinimumHeight = self.isMinimumHeight
        audioComponentEntity.title = self.title
        audioComponentEntity.detail = self.detail.jsonString
        parentPage.addToComponents(audioComponentEntity)
        return audioComponentEntity as! ComponentEntityType
    }
}

extension TextEditorComponentSnapshot {
    func store(in ctx: NSManagedObjectContext, parentComponentId: UUID) {

        let fetchRequest = TextEditorComponentEntity.findTextComponentEntityById(id: parentComponentId)
        let parentComponent = try! ctx.fetch(fetchRequest).first!

        let textEditorComponentSnapshotEntity = TextEditorComponentSnapshotEntity(context: ctx)
        textEditorComponentSnapshotEntity.snapshotID = self.snapshotID
        textEditorComponentSnapshotEntity.makingDate = self.makingDate
        textEditorComponentSnapshotEntity.detail = self.detail
        textEditorComponentSnapshotEntity.snapShotDescription = self.description
        textEditorComponentSnapshotEntity.saveMode = self.saveMode.rawValue

        parentComponent.snapshots.insert(textEditorComponentSnapshotEntity)
        textEditorComponentSnapshotEntity.component = parentComponent
    }
}

extension TableComponentSnapshot {
    func store(in ctx: NSManagedObjectContext, parentComponentId: UUID) {
        let fetchRequest = TableComponentEntity.findTableComponentEntityById(id: parentComponentId)
        let parentComponent = try! ctx.fetch(fetchRequest).first!
        
        let tableComponentSnapshotEntity = TableComponentSnapshotEntity(context: ctx)
        tableComponentSnapshotEntity.snapshotID = self.snapshotID
        tableComponentSnapshotEntity.makingDate = self.makingDate
        tableComponentSnapshotEntity.detail = self.detail.jsonString
        tableComponentSnapshotEntity.snapShotDescription = self.description
        tableComponentSnapshotEntity.saveMode = self.saveMode.rawValue

        parentComponent.snapshots.insert(tableComponentSnapshotEntity)
        tableComponentSnapshotEntity.component = parentComponent
    }
}
