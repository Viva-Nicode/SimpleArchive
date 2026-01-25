import Combine
import UIKit

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
