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

    func makeComponentView(from component: any PageComponent) -> UICollectionViewCell {
        guard let collectionView, let indexPath else { return UICollectionViewCell() }

        switch component {
            case let textEditorComponent as TextEditorComponent:
                let textEditorComponentView =
                    collectionView
                    .dequeueReusableCell(
                        withReuseIdentifier: TextEditorComponentView.identifierForUseCollectionView,
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
                    input: subject)

                return textEditorComponentView

            case let tableComponent as TableComponent:
                let tableCell =
                    collectionView
                    .dequeueReusableCell(
                        withReuseIdentifier: TableComponentView.reuseTableComponentIdentifier,
                        for: indexPath
                    ) as! TableComponentView

                tableCell.configure(component: tableComponent, input: subject)

                return tableCell

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

                audioCell.configure(component: audioComponent, input: subject)

                return audioCell

            default:
                return UICollectionViewCell()
        }
    }
}
