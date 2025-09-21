import UIKit
import Combine

extension MemoHomeViewModel: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        directoryStack.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MemoHomeTableView.reuseIdentifier, for: indexPath) as! MemoHomeTableView
        let subject = PassthroughSubject<MemoHomeSubViewInput, Never>()
        
        subscribe(input: subject.eraseToAnyPublisher())
        cell.configure(memoDirectoryModel: directoryStack[indexPath.item], subject: subject)
        return cell
    }
}
