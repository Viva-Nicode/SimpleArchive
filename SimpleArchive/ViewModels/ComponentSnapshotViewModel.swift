import Combine
import UIKit

@MainActor
final class ComponentSnapshotViewModel: NSObject, ViewModelType {

    typealias Input = ComponentSnapshotViewModelInput
    typealias Output = ComponentSnapshotViewModelOutput

    private var output = PassthroughSubject<Output, Never>()
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

    deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }

    @discardableResult
    func subscribe(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            guard let self else { return }

            switch event {
                case .viewDidLoad:
                    output.send(.viewDidLoad(snapshotRestorableComponent))

                case .willRestoreSnapshot:
                    restoreSnapshot()

                case .willRemoveSnapshot(let tappedSnapshotID):
                    removeSnapshot(tappedSnapshotID)

                case .willUpdateSnapshotMetaData(let index):
                    updateSnapshotMetaDataWhenScrolled(snapshotViewIndex: index)
            }
        }
        .store(in: &subscriptions)

        return output.eraseToAnyPublisher()
    }

    private func restoreSnapshot() {
        guard let currentViewedSnapshotID else { return }

        snapshotRestorableComponent.revertToSnapshot(snapshotID: currentViewedSnapshotID)
        componentSnapshotCoreDataRepository.revertComponentContents(modifiedComponent: snapshotRestorableComponent)
        output.send(.didRestoreSnapshot)
    }

    private func removeSnapshot(_ tappedSnapshotID: UUID) {
        guard currentViewedSnapshotID == tappedSnapshotID else { return }
        let removeResult = snapshotRestorableComponent.removeSnapshot(snapshotID: tappedSnapshotID)

        componentSnapshotCoreDataRepository.removeSnapshot(
            componentID: snapshotRestorableComponent.id,
            snapshotID: tappedSnapshotID)

        currentViewedSnapshotID = removeResult.nextSnapshotID
        output.send(.didRemoveSnapshot(removeResult.nextSnapshotMetaData, removeResult.removeSnapshotIndex))
    }

    private func updateSnapshotMetaDataWhenScrolled(snapshotViewIndex: Int) {
        let currentViewedSnapshot = snapshotRestorableComponent.snapshots[snapshotViewIndex]
        currentViewedSnapshotID = currentViewedSnapshot.snapshotID
        output.send(.didUpdateSnapshotMetaData(currentViewedSnapshot.getSnapshotMetaData()))
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
