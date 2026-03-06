import Combine
import UIKit

final class MemoPageComponentCollectionViewDataSource: NSObject, UICollectionViewDataSource {
    private var memoPage: MemoPageModel
    private var pageComponentViewFactory: PageComponentCollectionViewCellFactory

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
        pageComponentViewFactory.setIndexPath(indexPath: indexPath)
        let pageComponent = memoPage[indexPath.item]
        let pageComponentView = pageComponent.makeComponentView(using: pageComponentViewFactory)
        return pageComponentView
    }

    func freedDataSource() {
        pageComponentViewFactory.freedVMS()
    }

    func continuous() {
        pageComponentViewFactory.continuous()
    }
}
