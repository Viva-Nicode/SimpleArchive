import Combine
import UIKit

// 어떤 화면이 랜더링 되는 처리 작업도 사용자의 액션에따른 처리의 일부이고 과정이다.
// frameworks layer
// 컴포넌트는 뷰로 바뀌어야 할 룰이있고,
// 팩토리가 있으면 MemoPageComponentCollectionViewDataSource 이놈이 없어도 엔티티가있으면
// 어떤 뷰타입을 생성할 수있음

final class MemoPageComponentCollectionViewDataSource: NSObject, UICollectionViewDataSource {
    var memoPage: MemoPageModel
    var pageComponentViewFactory: PageComponentCollectionViewCellFactory

    init(pageComponentViewFactory: PageComponentCollectionViewCellFactory, memoPage: MemoPageModel) {
        self.memoPage = memoPage
        self.pageComponentViewFactory = pageComponentViewFactory
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        memoPage.compnentSize
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        pageComponentViewFactory.indexPath = indexPath
        let pageComponent = memoPage[indexPath.item]
        let pageComponentView = pageComponent.makeComponentView(using: pageComponentViewFactory)
        return pageComponentView
    }
}

final class PageComponentCollectionViewCellFactory: PageComponentViewFactoryType {
    var audioDataSources: [UUID: AudioComponentDataSource] = [:]
    var subject: PassthroughSubject<MemoPageViewInput, Never>
    var indexPath: IndexPath?

    weak var collectionView: UICollectionView?
    weak var audioContentsDataContainer: AudioContentsDataContainer?

    init(
        collectionView: UICollectionView,
        input: PassthroughSubject<MemoPageViewInput, Never>
    ) {
        self.collectionView = collectionView
        self.subject = input
    }

    func makeComponentView(from component: any PageComponent) -> UICollectionViewCell {
        guard let collectionView, let indexPath else { return UICollectionViewCell() }

        if let text = component as? TextEditorComponent {
            let textCell =
                collectionView
                .dequeueReusableCell(
                    withReuseIdentifier: TextEditorComponentView.identifierForUseCollectionView,
                    for: indexPath
                ) as! TextEditorComponentView

            textCell.configure(component: text, input: subject)

            return textCell

        } else if let table = component as? TableComponent {
            let tableCell =
                collectionView
                .dequeueReusableCell(
                    withReuseIdentifier: TableComponentView.reuseTableComponentIdentifier,
                    for: indexPath
                ) as! TableComponentView

            tableCell.configure(component: table, input: subject)

            return tableCell

        } else if let audio = component as? AudioComponent {
            let audioCell =
                collectionView
                .dequeueReusableCell(
                    withReuseIdentifier: AudioComponentView.reuseAudioComponentIdentifier,
                    for: indexPath
                ) as! AudioComponentView

            if let datasource = audioDataSources[audio.id] {
                print("audio Component \(audio.title) dataSource already exist.")
                audioCell.componentContentView.audioTrackTableView.dataSource = datasource
            } else {
                print("audio Component \(audio.title) dataSource create.")

                let audioContentsData = AudioContentsData(audioComponent: audio)
                audioContentsDataContainer?[audio.id] = audioContentsData

                let datasource = AudioComponentDataSource(audioContentsData: audioContentsData)
                audioDataSources[audio.id] = datasource

                audioCell.componentContentView.audioTrackTableView.dataSource = datasource
            }

            audioCell.configure(component: audio, input: subject)

            return audioCell
        } else {
            return UICollectionViewCell()
        }
    }
}
