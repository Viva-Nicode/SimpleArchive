import Combine
import UIKit


final class PageComponentCollectionViewCellFactory: PageComponentViewFactoryType {
    var audioDataSources: [UUID: AudioComponentDataSource] = [:]
    var pageComponentVMCache: [UUID: any PageComponentViewModelType] = [:]
    var subject: PassthroughSubject<MemoPageViewInput, Never>
    var indexPath: IndexPath?
    let audioContentsDataContainer: AudioContentsDataContainerType

    weak var collectionView: UICollectionView?

    init(
        collectionView: UICollectionView,
        input: PassthroughSubject<MemoPageViewInput, Never>,
        audioContentsDataContainer: AudioContentsDataContainerType
    ) {
        self.collectionView = collectionView
        self.subject = input
        self.audioContentsDataContainer = audioContentsDataContainer
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
                    pageActionDispatcher: subject)

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
                    pageActionDispatcher: subject)

                return tableComponentView

            case let audioComponent as AudioComponent:
                let audioCell =
                    collectionView
                    .dequeueReusableCell(
                        withReuseIdentifier: AudioComponentView.reuseAudioComponentIdentifier,
                        for: indexPath
                    ) as! AudioComponentView

                if let datasource = audioDataSources[audioComponent.id] {
                    audioCell.componentContentView.audioTrackTableView.dataSource = datasource
                } else {
                    if let audioContentsData = audioContentsDataContainer.getAudioContentsData(audioComponent.id) {
                        let datasource = AudioComponentDataSource(audioContentsData: audioContentsData)
                        audioDataSources[audioComponent.id] = datasource

                        audioCell.componentContentView.audioTrackTableView.dataSource = datasource
                    }
                }

                audioCell.configure(component: audioComponent, pageActionDispatcher: subject)

                return audioCell

            default:
                return UICollectionViewCell()
        }
    }
}
