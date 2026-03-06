import Combine
import UIKit

final class PageComponentCollectionViewCellFactory: PageComponentViewFactoryType {
    private var pageComponentVMCache: [UUID: any PageComponentViewModelType] = [:]
    private var componentActionDispatcherCache: [UUID: any PageComponentActionDispatcherType] = [:]
    private var pageActionDispatcher: PassthroughSubject<MemoPageViewInput, Never>
    private var indexPath: IndexPath?

    weak var collectionView: UICollectionView?

    init(
        collectionView: UICollectionView,
        input: PassthroughSubject<MemoPageViewInput, Never>,
    ) {
        self.collectionView = collectionView
        self.pageActionDispatcher = input
    }

    deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }

    func makeComponentView(from component: any PageComponent) -> UICollectionViewCell {
        guard let collectionView, let indexPath else { return UICollectionViewCell() }

        switch component {
            case let textEditorComponent as TextEditorComponent:
                let textEditorComponentView =
                    collectionView
                    .dequeueReusableCell(
                        withReuseIdentifier: TextEditorComponentView.reuseIdentifier,
                        for: indexPath
                    ) as! TextEditorComponentView

                let textEditorComponentViewModel =
                    pageComponentVMCache[textEditorComponent.id] as? TextEditorComponentViewModel
                    ?? {
                        DIContainer.shared.setArgument(TextEditorComponentViewModel.self, textEditorComponent)
                        let viewModel = DIContainer.shared.resolve(TextEditorComponentViewModel.self)
                        pageComponentVMCache[textEditorComponent.id] = viewModel
                        return viewModel
                    }()

                let textActionDispatcher: TextEditorComponentActionDispatcher =
                    componentActionDispatcherCache[textEditorComponent.id] as? TextEditorComponentActionDispatcher
                    ?? TextEditorComponentActionDispatcher()

                textActionDispatcher.clearSubscriptions()

                let textEditorComponentUIEventHandler = TextEditorComponentViewEventHandler(
                    contentsView: textEditorComponentView.componentContentView)

                textActionDispatcher.bindToViewModel(
                    viewModel: textEditorComponentViewModel,
                    UIEventHandler: textEditorComponentUIEventHandler)

                componentActionDispatcherCache[textEditorComponent.id] = textActionDispatcher

                textEditorComponentView.configureTextComponentForMemoPageView(
                    component: textEditorComponent,
                    viewModel: textEditorComponentViewModel,
                    pageActionDispatcher: pageActionDispatcher,
                    textActionDispatcher: textActionDispatcher)

                return textEditorComponentView

            case let tableComponent as TableComponent:
                let tableComponentView =
                    collectionView
                    .dequeueReusableCell(
                        withReuseIdentifier: TableComponentView.reuseIdentifier,
                        for: indexPath
                    ) as! TableComponentView

                let tableComponentViewModel =
                    pageComponentVMCache[tableComponent.id] as? TableComponentViewModel
                    ?? {
                        DIContainer.shared.setArgument(TableComponentViewModel.self, tableComponent)
                        let viewModel = DIContainer.shared.resolve(TableComponentViewModel.self)
                        pageComponentVMCache[tableComponent.id] = viewModel
                        return viewModel
                    }()

                let tableActionDispatcher: TableComponentActionDispatcher =
                    componentActionDispatcherCache[tableComponent.id] as? TableComponentActionDispatcher
                    ?? TableComponentActionDispatcher()

                tableActionDispatcher.clearSubscriptions()

                let tableComponentUIEventHandler = TableComponentViewEventHandler(
                    contentsView: tableComponentView.componentContentView)

                tableActionDispatcher.bindToViewModel(
                    viewModel: tableComponentViewModel,
                    UIEventHandler: tableComponentUIEventHandler)

                componentActionDispatcherCache[tableComponent.id] = tableActionDispatcher

                tableComponentView.configureTableComponentForMemoPageView(
                    component: tableComponent,
                    viewModel: tableComponentViewModel,
                    pageActionDispatcher: pageActionDispatcher,
                    actionDispatcher: tableActionDispatcher)

                return tableComponentView

            case let audioComponent as AudioComponent:
                let audioComponentView =
                    collectionView
                    .dequeueReusableCell(
                        withReuseIdentifier: AudioComponentView.reuseAudioComponentIdentifier,
                        for: indexPath
                    ) as! AudioComponentView

                let audioComponentViewModel =
                    pageComponentVMCache[audioComponent.id] as? AudioComponentViewModel
                    ?? {
                        DIContainer.shared.setArgument(AudioComponentViewModel.self, audioComponent)
                        let viewModel = DIContainer.shared.resolve(AudioComponentViewModel.self)
                        pageComponentVMCache[audioComponent.id] = viewModel
                        return viewModel
                    }()

                let audioActionDispatcher: AudioComponentActionDispatcher =
                    componentActionDispatcherCache[audioComponent.id] as? AudioComponentActionDispatcher
                    ?? AudioComponentActionDispatcher()

                audioActionDispatcher.clearSubscriptions()

                let audioComponentUIEventHandler = AudioComponentViewEventHandler(
                    componentView: audioComponentView.componentContentView)

                audioActionDispatcher.bindToViewModel(
                    viewModel: audioComponentViewModel,
                    UIEventHandler: audioComponentUIEventHandler)

                componentActionDispatcherCache[audioComponent.id] = audioActionDispatcher
                AudioComponentView.order[audioComponent.id] = indexPath

                audioComponentView.configureAudioComponentForMemoPageView(
                    component: audioComponent,
                    pageActionDispatcher: pageActionDispatcher,
                    audioActionDispatcher: audioActionDispatcher)

                return audioComponentView

            default:
                return UICollectionViewCell()
        }
    }

    func freedVMS() {
		pageComponentVMCache.values.forEach { $0.clearSubscriptions() }
		componentActionDispatcherCache.values.forEach{ $0.clearSubscriptions() } 
    }

    func continuous() {
        let activeAudioComponentIDs = pageComponentVMCache.compactMap { key, vm -> UUID? in
            guard let activeAudioVM = vm as? AudioComponentViewModel else { return nil }
            return activeAudioVM.isActiveAudioViewModel ? key : nil
        }

        activeAudioComponentIDs.forEach {
            pageComponentVMCache.removeValue(forKey: $0)
            componentActionDispatcherCache.removeValue(forKey: $0)
        }
    }

    func setIndexPath(indexPath: IndexPath) {
        self.indexPath = indexPath
    }
}
