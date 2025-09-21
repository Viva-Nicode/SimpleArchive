import Foundation

class DIContainer {

    static let shared = DIContainer()

    private init() {}

    private var dependencies: [String: Any] = [:]

    func register<T>(_ type: T.Type, dependency: Any) {
        let key = String(describing: type)
        dependencies[key] = dependency
    }

    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        return dependencies[key] as? T
    }
}

class DependencyConfigurator {

    static func configure() {
        configureMemoHomeViewModelDependencies()
        configureDormantBoxViewModelDependencies()
        configureMemoPageViewModelDependencies()
        configureComponentSnapshotViewModelDependencies()
    }

    private static func configureMemoHomeViewModelDependencies() {
        let memoDirectoryCoredataRepository = MemoDirectoryCoreDataRepository(coredataStack: CoreDataStack.manager)
        let memoPageCoredataRepository = MemoPageCoreDataRepository(coredataStack: CoreDataStack.manager)
        let directoryCreator = DirectoryCreator()
        let pageCreator = PageCreator(
            componentFactory: ComponentFactory(
                creator: TextEditorComponentCreator()))

        DIContainer.shared.register(MemoDirectoryCoreDataRepository.self, dependency: memoDirectoryCoredataRepository)
        DIContainer.shared.register(MemoPageCoreDataRepository.self, dependency: memoPageCoredataRepository)
        DIContainer.shared.register(DirectoryCreator.self, dependency: directoryCreator)
        DIContainer.shared.register(PageCreator.self, dependency: pageCreator)
    }

    private static func configureDormantBoxViewModelDependencies() {
        let dormantBoxCoredataRepository = DormantBoxCoreDataRepository(coredataStack: CoreDataStack.manager)
        DIContainer.shared.register(DormantBoxCoreDataRepository.self, dependency: dormantBoxCoredataRepository)
    }

    private static func configureMemoPageViewModelDependencies() {
        let memoComponentCoreDataRepository = MemoComponentCoreDataRepository(coredataStack: CoreDataStack.manager)
        let componentFactory = ComponentFactory(creator: TextEditorComponentCreator())
        DIContainer.shared.register(MemoComponentCoreDataRepository.self, dependency: memoComponentCoreDataRepository)
        DIContainer.shared.register(ComponentFactory.self, dependency: componentFactory)
    }

    private static func configureComponentSnapshotViewModelDependencies() {
        let componentSnapshotCoreDataRepository = ComponentSnapshotCoreDataRepository(
            coredataStack: CoreDataStack.manager)
        DIContainer.shared.register(
            ComponentSnapshotCoreDataRepository.self, dependency: componentSnapshotCoreDataRepository)
    }
}
