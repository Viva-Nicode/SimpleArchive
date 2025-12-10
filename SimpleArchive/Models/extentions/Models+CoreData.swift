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

        self.snapshots.forEach { $0.store(in: ctx, parentComponentId: self.id) }

        parentPage.addToComponents(textEditorComponentEntity)
    }

    func updatePageComponentEntityContents(in ctx: NSManagedObjectContext, entity: MemoComponentEntity) {
        if let textEditorComponentEntity = entity as? TextEditorComponentEntity {
            textEditorComponentEntity.contents = self.componentContents
        }
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
        self.snapshots.forEach { $0.store(in: ctx, parentComponentId: self.id) }

        parentPage.addToComponents(tableComponentEntity)
    }

    func updatePageComponentEntityContents(in ctx: NSManagedObjectContext, entity: MemoComponentEntity) {
        if let tableComponentEntity = entity as? TableComponentEntity,
            let mostRecentAction = actions.last
        {
            switch mostRecentAction {
                case .appendRow(let row):
                    let rowEntity = TableComponentRowEntity(context: ctx)
                    rowEntity.id = row.id
                    rowEntity.createdAt = row.createdAt
                    rowEntity.modifiedAt = row.modifiedAt
                    rowEntity.tableComponent = tableComponentEntity

                    for case let columnEntity as TableComponentColumnEntity in tableComponentEntity.columns {
                        let cellEntity = TableComponentCellEntity(context: ctx)
                        cellEntity.value = ""

                        cellEntity.column = columnEntity
                        cellEntity.row = rowEntity

                        rowEntity.addToCells(cellEntity)
                        columnEntity.addToCells(cellEntity)
                    }

                    let orderedRows = tableComponentEntity.mutableOrderedSetValue(forKey: "rows")
                    orderedRows.add(rowEntity)

                case .appendColumn(let column):
                    let columnEntity = TableComponentColumnEntity(context: ctx)
                    columnEntity.id = column.id
                    columnEntity.title = column.title
                    columnEntity.tableComponent = tableComponentEntity

                    for case let rowEntity as TableComponentRowEntity in tableComponentEntity.rows {
                        let cellEntity = TableComponentCellEntity(context: ctx)
                        cellEntity.value = ""

                        cellEntity.row = rowEntity
                        cellEntity.column = columnEntity

                        columnEntity.addToCells(cellEntity)
                        rowEntity.addToCells(cellEntity)
                    }

                    let orderedColumns = tableComponentEntity.mutableOrderedSetValue(forKey: "columns")
                    orderedColumns.add(columnEntity)

                case .removeRow(let rowID):
                    let fetchRequest = TableComponentRowEntity.findRowByID(rowID)
                    if let rowEntity = try? ctx.fetch(fetchRequest).first {
                        ctx.delete(rowEntity)
                    }

                case .editColumn(let columns):
                    let columnEntities = tableComponentEntity.mutableOrderedSetValue(forKey: "columns")
                    var columnList = columnEntities.array as! [TableComponentColumnEntity]

                    for (index, column) in columns.enumerated() {
                        if let fromIndex = columnList.firstIndex(where: { $0.id == column.id }) {
                            let fromIndexSet = IndexSet(integer: fromIndex)

                            columnEntities.moveObjects(at: fromIndexSet, to: index)
                            columnList.moveElement(src: fromIndex, des: index)
                            columnList[index].title = column.title
                        }
                    }

                    if columns.count < columnList.count {
                        for i in columns.count..<columnList.count {
                            ctx.delete(columnList[i])
                        }
                    }

                case .editCellValue(let rowID, let columnID, let value):
                    let fetchRequest = TableComponentCellEntity.findCellByID(rowID: rowID, colID: columnID)

                    if let cellEntity = try? ctx.fetch(fetchRequest).first {
                        cellEntity.value = value
                    }
            }
        }
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
        audioComponentEntity.detail = self.componentContents.jsonString
        parentPage.addToComponents(audioComponentEntity)
    }

    func updatePageComponentEntityContents(in ctx: NSManagedObjectContext, entity: MemoComponentEntity) {
        if let audioComponentEntity = entity as? AudioComponentEntity {
            audioComponentEntity.detail = componentContents.jsonString
        }
    }
}

extension TextEditorComponentSnapshot {
    func store(in ctx: NSManagedObjectContext, parentComponentId: UUID) {

        let fetchRequest = TextEditorComponentEntity.findTextComponentEntityById(id: parentComponentId)
        let parentComponent = try! ctx.fetch(fetchRequest).first!

        let textEditorComponentSnapshotEntity = TextEditorComponentSnapshotEntity(context: ctx)
        textEditorComponentSnapshotEntity.snapshotID = self.snapshotID
        textEditorComponentSnapshotEntity.makingDate = self.makingDate
        textEditorComponentSnapshotEntity.contents = self.contents
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
        tableComponentSnapshotEntity.contents = self.contents.jsonString
        tableComponentSnapshotEntity.snapShotDescription = self.description
        tableComponentSnapshotEntity.saveMode = self.saveMode.rawValue

        parentComponent.snapshots.insert(tableComponentSnapshotEntity)
        tableComponentSnapshotEntity.component = parentComponent
    }
}
