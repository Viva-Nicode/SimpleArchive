import Combine
import UIKit

final class DirectoryContentDataSource: NSObject, UICollectionViewDataSource, AttributesGeneratorType {

    private var directoryContents: MemoDirectoryModel
    private var input: PassthroughSubject<MemoHomeViewInput, Never>
    private var manualSortInfo: DirectoryContentsRenderInfo
    private let spacing = UIConstants.fileItemSpacing

    var isActivePanGesture: Bool = false
    var isActiveLongTapGesture: Bool = true

    init(
        directoryContents: MemoDirectoryModel,
        input: PassthroughSubject<MemoHomeViewInput, Never>,
        manualSortInfo: DirectoryContentsRenderInfo,
    ) {
        self.input = input
        self.directoryContents = directoryContents
        self.manualSortInfo = manualSortInfo
    }

    deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        directoryContents.items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let storageItem = directoryContents.items[indexPath.item]

        if directoryContents.sortBy == .manual {
            collectionView.register(FileItemView.self, forCellWithReuseIdentifier: "\(storageItem.id)")
        }

        if let cell =
            collectionView.dequeueReusableCell(
                withReuseIdentifier: directoryContents.sortBy == .manual
                    ? "\(storageItem.id)" : FileItemView.reuseIdentifier,
                for: indexPath) as? FileItemView
        {
            cell.configure(
                with: storageItem,
                dispatcher: input,
                isActivePanGesture: isActivePanGesture,
                isActiveLongTapGesture: isActiveLongTapGesture
            )

            return cell
        }
        return UICollectionViewCell()
    }

    func getAttr(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        let storageItem = directoryContents.items[indexPath.item]
        let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)

        if let idx = manualSortInfo[directoryContents.id].firstIndex(where: { $0.id == storageItem.id }) {
            let info = manualSortInfo[directoryContents.id][idx]
            switch info.frame {
                case .origin:
                    let size = UIConstants.ItemSize.small.size
                    let xOffset = size.width * CGFloat(indexPath.item % 4) + spacing * Double(indexPath.item % 4 + 1)
                    let yOffset = size.height * CGFloat(indexPath.item / 4) + spacing * Double(indexPath.item / 4 + 1)
                    attr.frame = .init(origin: .init(x: xOffset, y: yOffset), size: size)

                case .manual(let frame):
                    attr.frame = CGRect(CCGRect: frame)
                    attr.zIndex = Int(frame.z)
            }
        }

        return attr
    }

    func getHeight() -> CGFloat {
        (manualSortInfo[directoryContents.id].enumerated()
            .map { (i, info) in
                switch info.frame {
                    case .origin: return CGFloat((90 + spacing) * CGFloat(i / 4)) + 100
                    case .manual(let frame): return frame.y + frame.h
                }
            }
            .max() ?? .zero) + 100
    }
}

extension DirectoryContentDataSource: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let fileTapped = directoryContents.items[indexPath.item]

        switch fileTapped {
            case is MemoPageModel:
                input.send(.willNavigatePageView(indexPath.item))

            case is MemoDirectoryModel:
                collectionView.isUserInteractionEnabled = false
                input.send(.willMoveToFollowingDirectory(indexPath.item))

            default:
                break
        }
    }

    func collectionView(
        _ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath
    ) {
        collectionView.isUserInteractionEnabled = true
    }
}
