import Combine
import Foundation

final class DIContainer {
    typealias DependencyTypeKey = String
    typealias ArgumentTypeKey = String

    static let shared = DIContainer()
    private init() {}

    private var dependencyCreator: [DependencyTypeKey: () -> Any] = [:]
    private var singletonCache: [DependencyTypeKey: Any] = [:]
    private var argumentRequirements: [DependencyTypeKey: [ArgumentTypeKey: Any?]] = [:]

    fileprivate func register<T>(
        _ type: T.Type,
        isSingleton: Bool = false,
        requiredArgs: [Any.Type] = [],
        injector: @escaping () -> T
    ) {
        let dependencyKey = String(describing: type)

        if !requiredArgs.isEmpty {
            var argsMap: [String: Any?] = [:]
            requiredArgs.forEach { argType in
                argsMap[String(describing: argType)] = nil
            }
            argumentRequirements[dependencyKey] = argsMap
        }

        if isSingleton {
            dependencyCreator[dependencyKey] = { [weak self] in
                if let cached = self?.singletonCache[dependencyKey] { return cached }
                let dependency = injector()
                self?.singletonCache[dependencyKey] = dependency
                return dependency
            }
        } else {
            dependencyCreator[dependencyKey] = injector
        }
    }

    func setArgument<T, Arg>(_ type: T.Type, _ arg: Arg) {
        let dependencyKey = String(describing: type)
        let argumentKey = String(describing: Arg.self)

        guard argumentRequirements[dependencyKey] != nil else {
            myLog("\(dependencyKey)가 존재하지 않으므로 setArgument불가")
            return
        }

        argumentRequirements[dependencyKey]?[argumentKey] = arg
    }

    fileprivate func getArgument<Arg>(_ dependenCyType: Any.Type) -> Arg {
        let dependencyKey = String(describing: dependenCyType)
        let argumentKey = String(describing: Arg.self)

        guard let arg = argumentRequirements[dependencyKey]?[argumentKey] as? Arg else {
            myLog(String(describing: argumentRequirements[dependencyKey]))
            fatalError("\(dependencyKey)를 위한 \(argumentKey) 추가 데이터가 주입되지 않흠")
        }
        return arg
    }

    func resolve<T>(_ type: T.Type) -> T {
        let dependencyKey = String(describing: type)

        // 추가 데이터가 없으면 통과. 있다면 모든 추가데이터가 nil이 아닌지 확인
        if let requirements = argumentRequirements[dependencyKey] {
            for (argKey, arg) in requirements {
                if arg == nil {
                    fatalError("\(dependencyKey) 생성에 필요한 \(argKey) 데이터가 nil임.")
                }
            }
        }

        guard let creator = dependencyCreator[dependencyKey], let dependency = creator() as? T else {
            fatalError("\(dependencyKey)의 의존성이 등록되지 않음")
        }

        // 객체 생성에 필요한 추가 데이터 제거
        if var requirements = argumentRequirements[dependencyKey] {
            for argKey in requirements.keys {
                requirements[argKey] = nil
            }
            argumentRequirements[dependencyKey] = requirements
        }
        return dependency
    }
}

@MainActor
final class DependencyConfigurator {
    static func configureDependencies() {
        configureCommonDependencies()

        configureMemoHomeViewModelDependencies()
        configureMemoPageViewModelDependencies()

        configureTextEditorComponentViewModelDependencies()
        configureTableComponentViewModelDependencies()

        configureComponentSnapshotViewModelDependencies()
        configureDormantBoxViewModelDependencies()
        configureSingleTableComponentViewModelDependencies()
        configureSingleAudioComponentViewModelDependencies()
    }

    private static func configureCommonDependencies() {
        let container = DIContainer.shared
        let coreDataStack = CoreDataStack.manager

        container.register(MemoDirectoryCoreDataRepository.self, isSingleton: true) {
            MemoDirectoryCoreDataRepository(coredataStack: coreDataStack)
        }

        container.register(MemoPageCoreDataRepository.self, isSingleton: true) {
            MemoPageCoreDataRepository(coredataStack: coreDataStack)
        }

        container.register(MemoComponentCoreDataRepository.self, isSingleton: true) {
            MemoComponentCoreDataRepository(coredataStack: coreDataStack)
        }

        container.register(ComponentSnapshotCoreDataRepository.self, isSingleton: true) {
            ComponentSnapshotCoreDataRepository(coredataStack: coreDataStack)
        }

        container.register(DormantBoxCoreDataRepository.self, isSingleton: true) {
            DormantBoxCoreDataRepository(coredataStack: coreDataStack)
        }

        container.register(AudioFileManagerType.self, isSingleton: true) {
            AudioFileManager()
        }

        container.register(AudioDownloaderType.self, isSingleton: true) {
            AudioDownloader()
        }

        container.register(AudioTrackControllerType.self, isSingleton: true) {
            AudioTrackController()
        }

        container.register(ComponentFactoryType.self) {
            ComponentFactory(creator: TextEditorComponentCreator())
        }
    }

    private static func configureMemoHomeViewModelDependencies() {
        let container = DIContainer.shared

        container.register(DirectoryCreator.self) { DirectoryCreator() }

        container.register(PageCreator.self) {
            let factory = container.resolve(ComponentFactoryType.self)
            return PageCreator(componentFactory: factory)
        }

        container.register(MemoHomeViewModel.self) {
            MemoHomeViewModel(
                memoDirectoryCoredataReposotory: container.resolve(MemoDirectoryCoreDataRepository.self),
                memoPageCoredataReposotory: container.resolve(MemoPageCoreDataRepository.self),
                directoryCreator: container.resolve(DirectoryCreator.self),
                pageCreator: container.resolve(PageCreator.self)
            )
        }
    }

    private static func configureMemoPageViewModelDependencies() {
        let container = DIContainer.shared

        container.register(MemoPageViewModel.self, requiredArgs: [MemoPageModel.self]) {
            let memoPageData = container.getArgument(MemoPageViewModel.self) as MemoPageModel

            return MemoPageViewModel(
                componentFactory: container.resolve(ComponentFactoryType.self),
                memoComponentCoredataReposotory: container.resolve(MemoComponentCoreDataRepository.self),
                componentSnapshotCoreDataRepository: container.resolve(ComponentSnapshotCoreDataRepository.self),
                audioDownloader: container.resolve(AudioDownloaderType.self),
                audioFileManager: container.resolve(AudioFileManagerType.self),
                audioTrackController: container.resolve(AudioTrackControllerType.self),
                memoPage: memoPageData
            )
        }
    }

    private static func configureComponentSnapshotViewModelDependencies() {
        let container = DIContainer.shared

        container.register(
            ComponentSnapshotViewModel.self,
            requiredArgs: [(any SnapshotRestorablePageComponent).self, (any ComponentSnapshotType).self]
        ) {
            let snapshotRestorableComponent =
                container
                .getArgument(ComponentSnapshotViewModel.self) as (any SnapshotRestorablePageComponent)
            let trackingSnapshot =
                container
                .getArgument(ComponentSnapshotViewModel.self) as (any ComponentSnapshotType)

            return ComponentSnapshotViewModel(
                componentSnapshotCoreDataRepository: container.resolve(ComponentSnapshotCoreDataRepository.self),
                snapshotRestorableComponent: snapshotRestorableComponent,
                trackingSnapshot: trackingSnapshot
            )
        }
    }

    private static func configureDormantBoxViewModelDependencies() {
        let container = DIContainer.shared

        typealias Subject = PassthroughSubject<[MemoPageModel], Never>

        container.register(
            DormantBoxViewModel.self,
            requiredArgs: [Subject.self].self
        ) {
            let subject = DIContainer.shared.getArgument(DormantBoxViewModel.self) as Subject

            return DormantBoxViewModel(
                dormantBoxCoredataRepository: container.resolve(DormantBoxCoreDataRepository.self),
                restoredPageListSubject: subject,
                audioFileManager: container.resolve(AudioFileManagerType.self)
            )
        }
    }

    private static func configureTextEditorComponentViewModelDependencies() {
        let container = DIContainer.shared

        container.register(TextEditorComponentViewModel.self, requiredArgs: [TextEditorComponent.self]) {
            let textEditorComponent =
                container.getArgument(TextEditorComponentViewModel.self) as TextEditorComponent
            let memoComponentCoreDataRepository = container.resolve(MemoComponentCoreDataRepository.self)
            let textEditorComponentInteractor = TextEditorComponentInteractor(
                textEditorComponent: textEditorComponent,
                memoComponentCoredataReposotory: memoComponentCoreDataRepository)
            return TextEditorComponentViewModel(textEditorComponentInteractor: textEditorComponentInteractor)
        }
    }

    private static func configureTableComponentViewModelDependencies() {
        let container = DIContainer.shared

        container.register(TableComponentViewModel.self, requiredArgs: [TableComponent.self]) {
            let tableComponent =
                container.getArgument(TableComponentViewModel.self) as TableComponent
            let memoComponentCoreDataRepository = container.resolve(MemoComponentCoreDataRepository.self)
            let tableComponentInteractor = TableComponentInteractor(
                tableComponent: tableComponent,
                memoComponentCoredataReposotory: memoComponentCoreDataRepository)
            return TableComponentViewModel(tableComponentInteractor: tableComponentInteractor)
        }
    }

    private static func configureSingleTableComponentViewModelDependencies() {
        let container = DIContainer.shared

        container.register(SingleTablePageViewModel.self, requiredArgs: [TableComponent.self, String.self]) {
            let tableComponent = container.getArgument(SingleTablePageViewModel.self) as TableComponent
            let pageName = container.getArgument(SingleTablePageViewModel.self) as String
            return SingleTablePageViewModel(
                coredataReposotory: container.resolve(MemoComponentCoreDataRepository.self),
                tableComponent: tableComponent,
                pageTitle: pageName
            )
        }
    }

    private static func configureSingleAudioComponentViewModelDependencies() {
        let container = DIContainer.shared

        container.register(SingleAudioPageViewModel.self, requiredArgs: [AudioComponent.self, String.self]) {
            let audioComponent = container.getArgument(SingleAudioPageViewModel.self) as AudioComponent
            let pageName = container.getArgument(SingleAudioPageViewModel.self) as String

            return SingleAudioPageViewModel(
                coredataReposotory: container.resolve(MemoComponentCoreDataRepository.self),
                audioComponent: audioComponent,
                audioDownloader: container.resolve(AudioDownloaderType.self),
                audioFileManager: container.resolve(AudioFileManagerType.self),
                audioTrackController: container.resolve(AudioTrackControllerType.self),
                pageTitle: pageName)
        }
    }
}
