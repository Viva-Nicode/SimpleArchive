import UIKit
import Combine

extension MemoPageViewModel: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        memoPage.compnentSize
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let subject = PassthroughSubject<MemoPageViewInput, Never>()
        subscribe(input: subject.eraseToAnyPublisher())
        
        return memoPage[indexPath.item].getCollectionViewComponentCell(
            collectionView,
            indexPath,
            isReadOnly: isReadOnly,
            subject: subject)
    }
}
