import UIKit

protocol ComponentsPageCollectionViewLayoutDelegate: AnyObject {
    func collectionView(heightForItemAt indexPath: IndexPath) -> CGFloat
}

final class ComponentsPageCollectionViewLayout: UICollectionViewFlowLayout {

    weak var delegate: ComponentsPageCollectionViewLayoutDelegate?
    private var cache: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0

    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        return collectionView.bounds.width - 40
    }

    override var collectionViewContentSize: CGSize {
        CGSize(width: contentWidth, height: contentHeight)
    }

    override func prepare() {
        super.prepare()

        guard let collectionView = collectionView else { return }
        collectionView.contentInset = UIEdgeInsets(
            top: UIConstants.memoPageViewControllerCollectionViewHeaderHeight,
            left: 0,
            bottom: UIConstants.memoPageViewControllerCollectionViewFooterHeight,
            right: 0)
        cache.removeAll()

        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        let availableWidth = contentWidth - sectionInset.left - sectionInset.right
        var yOffset: CGFloat = sectionInset.top

        for item in 0..<numberOfItems {
            let indexPath = IndexPath(item: item, section: 0)
            let itemHeight =
                delegate?.collectionView(heightForItemAt: indexPath)
                ?? itemSize.height

            let frame = CGRect(
                x: (collectionView.bounds.width - availableWidth) / 2,
                y: yOffset,
                width: availableWidth,
                height: itemHeight
            )

            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = frame

            cache.append(attributes)

            yOffset += itemHeight + minimumLineSpacing
            contentHeight = max(contentHeight, frame.maxY + sectionInset.bottom)
        }
    }

    override func layoutAttributesForSupplementaryView(
        ofKind elementKind: String,
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        cache.first { $0.representedElementKind == elementKind && $0.indexPath == indexPath }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        cache.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        cache.first { $0.indexPath == indexPath }
    }
}
