import Combine
import UIKit

@MainActor class ComponentSnapshotViewModel: NSObject, ViewModelType {

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

    deinit { print("ComponentSnapshotViewModel deinit") }

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
                    let currentViewedSnapshot = snapshotRestorableComponent.snapshots[index]
                    currentViewedSnapshotID = currentViewedSnapshot.snapshotID
                    output.send(.didUpdateSnapshotMetaData(currentViewedSnapshot.getSnapshotMetaData()))

            }
        }
        .store(in: &subscriptions)

        return output.eraseToAnyPublisher()
    }

    private func restoreSnapshot() {
        if let currentViewedSnapshotID {
            snapshotRestorableComponent.revertToSnapshot(snapshotID: currentViewedSnapshotID)
            componentSnapshotCoreDataRepository.revertComponentContents(modifiedComponent: snapshotRestorableComponent)
            output.send(.didRestoreSnapshot)
        }
    }

    private func removeSnapshot(_ tappedSnapshotID: UUID) {
        guard currentViewedSnapshotID == tappedSnapshotID else { return }
        let removeResult = snapshotRestorableComponent.removeSnapshot(at: tappedSnapshotID)

        componentSnapshotCoreDataRepository.removeSnapshot(
            componentID: snapshotRestorableComponent.id,
            snapshotID: tappedSnapshotID)

        currentViewedSnapshotID = removeResult.nextSnapshotID

        output.send(.didRemoveSnapshot(removeResult.nextSnapshotMetaData, removeResult.removeSnapshotIndex))
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
