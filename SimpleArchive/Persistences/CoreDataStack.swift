import Combine
import CoreData
import Foundation

class CoreDataStack: PersistentStore {
    private let isStoreLoaded = CurrentValueSubject<Bool, Error>(false)
    private let container: NSPersistentContainer
    private let coredataTaskQueue = DispatchQueue(label: "coredata")
    private let queueKey = DispatchSpecificKey<String>()
    private var resetChildContext: (() -> Void)?
    public static let manager: CoreDataStack = .init()

    private init() {
        container = NSPersistentContainer(name: "SimpleArchive")

        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        }

        coredataTaskQueue.setSpecific(key: queueKey, value: "coredata")
        coredataTaskQueue.async { [weak isStoreLoaded, weak container] in
            container?
                .loadPersistentStores { (storeDescription, error) in
                    DispatchQueue.main.async {
                        if let error = error {
                            isStoreLoaded?.send(completion: .failure(error))
                        } else {
                            container?.viewContext.configureAsReadOnlyContext()
                            isStoreLoaded?.send(true)
                        }
                    }
                }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleContextDidSave(notification:)),
            name: .NSManagedObjectContextDidSave, object: nil
        )
    }

    func fetch<T, V>(_ fetchRequest: NSFetchRequest<T>, map: @escaping (T) throws -> V?) -> AnyPublisher<[V], Error> {
        let fetch = Future<[V], Error> { [weak container] promise in
            guard let context = container?.viewContext else { return }
            context.performAndWait {
                do {
                    let managedObjects = try context.fetch(fetchRequest)
                    let results = try managedObjects.compactMap { try map($0) }
                    promise(.success(results))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        return
            onStoreIsReady
            .flatMap { fetch }
            .eraseToAnyPublisher()
    }

    func update<Result>(_ operation: @escaping (NSManagedObjectContext) throws -> Result) -> AnyPublisher<Result, Error>
    {
        let update = Future<Result, Error> { [weak coredataTaskQueue, weak container] promise in
            coredataTaskQueue?
                .async {
                    guard let context = container?.newBackgroundContext() else { return }
                    self.resetChildContext = nil
                    self.resetChildContext = { [context] () -> Void in context.reset() }

                    context.configureAsUpdateContext()

                    context.performAndWait {
                        do {
                            let result: Result = try operation(context)
                            if context.hasChanges {
                                try context.save()
                            }
                            promise(.success(result))
                        } catch {
                            context.reset()
                            print(error.localizedDescription)
                            promise(.failure(error))
                        }
                    }
                }
        }

        return
            onStoreIsReady
            .flatMap { update }
            .eraseToAnyPublisher()
    }

    private var onStoreIsReady: AnyPublisher<Void, Error> {
        isStoreLoaded
            .filter { $0 }
            .map { _ in }
            .eraseToAnyPublisher()
    }

    @objc private func handleContextDidSave(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }

        if let deletedObjects = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> {
            for deletedObject in deletedObjects {
                AppDelegate.prettyPrint("deleted : \(type(of: deletedObject))")
            }
        }

        if let insertedObjects = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> {
            for insertedObject in insertedObjects {
                if let directoryEntity = insertedObject as? MemoDirectoryEntity {
                    AppDelegate.prettyPrint("created Directory Entity : \(directoryEntity.name)")
                } else if let pageEntity = insertedObject as? MemoPageEntity {
                    AppDelegate.prettyPrint("created Page Entity : \(pageEntity.name)")
                }
            }
        }
    }
}

extension NSManagedObjectContext {

    func configureAsReadOnlyContext() {
        automaticallyMergesChangesFromParent = true
        mergePolicy = NSRollbackMergePolicy
        undoManager = nil
        shouldDeleteInaccessibleFaults = true
    }

    func configureAsUpdateContext() {
        mergePolicy = NSOverwriteMergePolicy
        undoManager = nil
    }
}

#if DEBUG
    extension CoreDataStack {

        func cleanAllCoreDataEntities() {
            do {
                let context = container.viewContext
                let entityDescriptions = container.managedObjectModel.entities

                for entityDescription in entityDescriptions {

                    guard let entityName = entityDescription.name else { continue }
                    if entityDescription.isAbstract { continue }

                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)

                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    deleteRequest.resultType = .resultTypeObjectIDs

                    let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                    if let objectIDs = result?.result as? [NSManagedObjectID] {
                        let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDs]
                        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                    }
                }
            } catch {
                print("Failed to delete all data: \(error.localizedDescription)")
            }
        }

        func cleanAllCoreDataEntitiesExceptSystemDirectories() {
            do {
                let context = container.viewContext
                let entityDescriptions = container.managedObjectModel.entities

                for entityDescription in entityDescriptions {

                    guard let entityName = entityDescription.name else { continue }
                    if entityDescription.isAbstract { continue }

                    if entityName == "MemoDirectoryEntity" {
                        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)

                        let predicate = NSPredicate(format: "parentDirectory != nil")
                        fetchRequest.predicate = predicate

                        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                        deleteRequest.resultType = .resultTypeObjectIDs

                        let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                        if let objectIDs = result?.result as? [NSManagedObjectID] {
                            let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDs]
                            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                        }
                        continue
                    }

                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)

                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    deleteRequest.resultType = .resultTypeObjectIDs

                    let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                    if let objectIDs = result?.result as? [NSManagedObjectID] {
                        let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDs]
                        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                    }
                }
            } catch {
                print("Failed to delete all data: \(error.localizedDescription)")
            }
        }

        func prepareCoreDataEntities(storageItem: some StorageItem, systemDirectory: SystemDirectories) throws {
            let systemDirectoryID = systemDirectory.getId()!
            let ctx = self.container.viewContext
            let mainDirectoryEntity = try ctx
                .fetch(
                    MemoDirectoryEntity
                        .findDirectoryEntityById(id: systemDirectoryID)
                )
                .first!

            storageItem.store(in: ctx, parentDirectory: mainDirectoryEntity)
            try ctx.save()
        }

        func printAllEntities() {
            do {
                let context = container.viewContext
                let entityDescriptions = container.managedObjectModel.entities

                for entityDescription in entityDescriptions {
                    guard let entityName = entityDescription.name else { continue }
                    if entityDescription.isAbstract { continue }
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                    let count = try context.count(for: fetchRequest)
                    print("Entity: \(entityName), Count: \(count)")
                }
            } catch {
                print("Failed to fetch entities: \(error.localizedDescription)")
            }
        }
    }
#endif
