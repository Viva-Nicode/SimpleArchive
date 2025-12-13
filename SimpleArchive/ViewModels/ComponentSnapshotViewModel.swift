import Combine
import UIKit

@MainActor class ComponentSnapshotViewModel: NSObject, ViewModelType {

    typealias Input = ComponentSnapshotViewModelInput
    typealias Output = ComponentSnapshotViewModelOutput

    private var output = PassthroughSubject<Output, Never>()
    private var errorOutput = PassthroughSubject<ComponentSnapshotViewModelError, Never>()
    private var subscriptions = Set<AnyCancellable>()

    private(set) var snapshotRestorableComponent: any SnapshotRestorablePageComponent
    private var currentViewedSnapshotID: UUID?
    private var componentSnapshotCoreDataRepository: ComponentSnapshotCoreDataRepositoryType

    init(
        componentSnapshotCoreDataRepository: ComponentSnapshotCoreDataRepositoryType,
        snapshotRestorableComponent: any SnapshotRestorablePageComponent
    ) {
        self.componentSnapshotCoreDataRepository = componentSnapshotCoreDataRepository
        self.snapshotRestorableComponent = snapshotRestorableComponent
        self.currentViewedSnapshotID = snapshotRestorableComponent.snapshots.first?.snapshotID
    }

    deinit { print("ComponentSnapshotViewModel deinit") }

    @discardableResult
    func subscribe(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            guard let self else { return }

            switch event {
                case .viewDidLoad:
                    let mostRecentSnapshotMetadata = snapshotRestorableComponent.snapshots.first?.getSnapshotMetaData()
                    output.send(.viewDidLoad(mostRecentSnapshotMetadata))

                case .restoreSnapshot:
                    restoreSnapshot()

                case .removeSnapshot(let tappedSnapshotID):
                    removeSnapshot(tappedSnapshotID)
            }
        }
        .store(in: &subscriptions)

        return output.eraseToAnyPublisher()
    }

    func errorSubscribe() -> AnyPublisher<ComponentSnapshotViewModelError, Never> {
        errorOutput.eraseToAnyPublisher()
    }

    private func restoreSnapshot() {
        do {
            if let currentViewedSnapshotID {
                try snapshotRestorableComponent.revertToSnapshot(snapshotID: currentViewedSnapshotID)
                componentSnapshotCoreDataRepository
                    .updateComponentContentChanges(modifiedComponent: snapshotRestorableComponent)
                output.send(.didCompleteRestoreSnapshot)
            } else {
                errorOutput.send(.unownedError)
            }
        } catch .canNotFoundSnapshot(let snapshotID) {
            errorOutput.send(.canNotFoundSnapshot(snapshotID))
        } catch {
            errorOutput.send(.unownedError)
        }
    }

    private func removeSnapshot(_ tappedSnapshotID: UUID) {

        guard currentViewedSnapshotID == tappedSnapshotID else {
            errorOutput.send(.componentIDMismatchError)
            return
        }

        do {
            let removeResult = try snapshotRestorableComponent.removeSnapshot(snapshotID: tappedSnapshotID)
            componentSnapshotCoreDataRepository.removeSnapshot(
                componentID: snapshotRestorableComponent.id, snapshotID: tappedSnapshotID)

            if let nextViewedSnapshotIndex = removeResult.nextViewedSnapshotIndex {
                let nextViewedSnapshot = snapshotRestorableComponent.snapshots[nextViewedSnapshotIndex]
                currentViewedSnapshotID = nextViewedSnapshot.snapshotID

                let nextViewedSnapshotMetadata = nextViewedSnapshot.getSnapshotMetaData()
                output.send(.didCompleteRemoveSnapshot(nextViewedSnapshotMetadata, removeResult.removedSnapshotIndex))
            } else {
                currentViewedSnapshotID = nil
                output.send(.didCompleteRemoveSnapshot(nil, removeResult.removedSnapshotIndex))
            }
        } catch .canNotFoundSnapshot(let snapshotID) {
            errorOutput.send(.canNotFoundSnapshot(snapshotID))
        } catch {
            errorOutput.send(.unownedError)
        }
    }
}

extension ComponentSnapshotViewModel: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        snapshotRestorableComponent.snapshots.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        let subject = PassthroughSubject<ComponentSnapshotViewModelInput, Never>()
        subscribe(input: subject.eraseToAnyPublisher())

        return snapshotRestorableComponent.getCollectionViewSnapShotCell(collectionView, indexPath, subject: subject)
    }

    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.size.width - 80, height: collectionView.bounds.size.width - 80)
    }

    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets { .init(top: 20, left: 40, bottom: 0, right: 40) }

    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat { 20 }
}

extension ComponentSnapshotViewModel: UICollectionViewDelegate {

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {

        let cellWidthIncludingSpacing = UIView.screenWidth - 60

        // targetContentOff을 이용하여 x좌표가 얼마나 이동했는지 확인
        // 이동한 x좌표 값과 item의 크기를 비교하여 몇 페이징이 될 것인지 값 설정
        var offset = targetContentOffset.pointee
        let index = (offset.x + scrollView.contentInset.left) / cellWidthIncludingSpacing
        var roundedIndex = round(index)

        // scrollView, targetContentOffset의 좌표 값으로 스크롤 방향을 알 수 있다.
        // index를 반올림하여 사용하면 item의 절반 사이즈만큼 스크롤을 해야 페이징이 된다.
        // 스크로로 방향을 체크하여 올림,내림을 사용하면 좀 더 자연스러운 페이징 효과를 낼 수 있다.
        if scrollView.contentOffset.x > targetContentOffset.pointee.x {
            roundedIndex = floor(index)
        } else if scrollView.contentOffset.x < targetContentOffset.pointee.x {
            roundedIndex = ceil(index)
        } else {
            roundedIndex = round(index)
        }

        // 위 코드를 통해 페이징 될 좌표값을 targetContentOffset에 대입하면 된다.
        offset = CGPoint(
            x: roundedIndex * cellWidthIncludingSpacing - scrollView.contentInset.left,
            y: -scrollView.contentInset.top)
        targetContentOffset.pointee = offset

        let currentViewedSnapshot = snapshotRestorableComponent.snapshots[Int(roundedIndex)]
        currentViewedSnapshotID = currentViewedSnapshot.snapshotID
        output.send(.hasScrolled(currentViewedSnapshot.getSnapshotMetaData()))
    }
}

#if DEBUG
    extension ComponentSnapshotViewModel {
        convenience init(
            snapshotRestorableComponent: any SnapshotRestorablePageComponent,
            componentSnapshotCoreDataRepository: ComponentSnapshotCoreDataRepositoryType,
            initialViewedSnapshotID: UUID?
        ) {
            self.init(
                componentSnapshotCoreDataRepository: componentSnapshotCoreDataRepository,
                snapshotRestorableComponent: snapshotRestorableComponent)
            self.currentViewedSnapshotID = initialViewedSnapshotID
        }
    }
#endif
