import CoreData

extension MemoDirectoryModel {
    func persistToPersistentStorage(using persistence: StorageItemPersistenceCreatorType) {
        persistence.persistDirectory(directory: self)
    }
}

extension MemoPageModel {
    func persistToPersistentStorage(using persistence: StorageItemPersistenceCreatorType) {
        persistence.persistPage(page: self)
    }
}

extension TextEditorComponent {
    func persistToPersistentStorage(using persistence: PageComponentPersistenceCreatorType) {
        persistence.persistTextEditorComponent(textComponent: self)
    }
}

extension TableComponent {
    func persistToPersistentStorage(using persistence: PageComponentPersistenceCreatorType) {
        persistence.persistTableComponent(tableComponent: self)
    }
}

extension AudioComponent {
    func persistToPersistentStorage(using persistence: PageComponentPersistenceCreatorType) {
        persistence.persistAudioComponent(audioComponent: self)
    }
}

extension TextEditorComponentSnapshot {
    func persistToPersistentStorage(using persistence: ComponentSnapshotPersistenceCreatorType) {
        persistence.persistTextEditorComponentSnapshot(snapshot: self)
    }
}

extension TableComponentSnapshot {
    func persistToPersistentStorage(using persistence: ComponentSnapshotPersistenceCreatorType) {
        persistence.persistTableComponentSnapshot(snapshot: self)
    }
}
