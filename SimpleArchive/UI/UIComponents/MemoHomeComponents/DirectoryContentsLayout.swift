import UIKit

protocol AttributesGeneratorType: AnyObject {
    func getAttr(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes
    func getHeight() -> CGFloat
}

final class DirectoryContentsLayout: UICollectionViewLayout {
    private var contentWidth: CGFloat = 0
    private let spacing = UIConstants.fileItemSpacing

    weak var delegate: AttributesGeneratorType?

    override init() {
        super.init()
        if let collectionView { contentWidth = collectionView.bounds.width }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var collectionViewContentSize: CGSize {
        CGSize(width: contentWidth, height: delegate?.getHeight() ?? .zero)
    }

    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath)
        -> UICollectionViewLayoutAttributes?
    {
        guard let attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath) else { return nil }
        return attributes
    }

    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath)
        -> UICollectionViewLayoutAttributes?
    {
        guard let attributes = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath) else { return nil }
        return attributes
    }

    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView else { return nil }
        var visibileLayoutAttributes: [UICollectionViewLayoutAttributes] = []

        for i in 0..<collectionView.numberOfItems(inSection: 0) {
            if let attr = delegate?.getAttr(at: IndexPath(item: i, section: 0)) {
                if attr.frame.intersects(rect) {
                    visibileLayoutAttributes.append(attr)
                }
            }
        }

        return visibileLayoutAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        delegate?.getAttr(at: indexPath)
    }
}
