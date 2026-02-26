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

                textEditorComponentView.configureTextComponentForMemoPageView(
                    component: textEditorComponent,
                    viewModel: textEditorComponentViewModel,
                    pageActionDispatcher: pageActionDispatcher)

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

                tableComponentView.configureTableComponentForMemoPageView(
                    component: tableComponent,
                    viewModel: tableComponentViewModel,
                    pageActionDispatcher: pageActionDispatcher)

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

                let audioComponentUIEventHandler = AudioComponentViewEventHandler(componentView: audioComponentView)

                audioActionDispatcher.bindToViewModel(
                    viewModel: audioComponentViewModel,
                    UIEventHandler: audioComponentUIEventHandler)

				componentActionDispatcherCache[audioComponent.id] = audioActionDispatcher

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
    }

    func setIndexPath(indexPath: IndexPath) {
        self.indexPath = indexPath
    }
}
