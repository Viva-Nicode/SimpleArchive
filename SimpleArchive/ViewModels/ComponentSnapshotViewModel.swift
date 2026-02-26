import Combine
import UIKit

@MainActor final class ComponentSnapshotViewModel: NSObject {

    private var output = PassthroughSubject<Event, Never>()
    private var subscriptions = Set<AnyCancellable>()

    private var snapshotRestorableComponent: any SnapshotRestorablePageComponent
    private var currentViewedSnapshotID: UUID?
    private var componentSnapshotCoreDataRepository: ComponentSnapshotCoreDataRepositoryType
    private var trackingSnapshot: any ComponentSnapshotType
    let updateTrackingSnapshotSignal = PassthroughSubject<Void, Never>()

    init(
        componentSnapshotCoreDataRepository: ComponentSnapshotCoreDataRepositoryType,
        snapshotRestorableComponent: any SnapshotRestorablePageComponent,
        trackingSnapshot: any ComponentSnapshotType
    ) {
        self.componentSnapshotCoreDataRepository = componentSnapshotCoreDataRepository
        self.snapshotRestorableComponent = snapshotRestorableComponent
        self.trackingSnapshot = trackingSnapshot
        self.currentViewedSnapshotID = snapshotRestorableComponent.snapshots.first?.snapshotID
    }

    deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }

    @discardableResult
    func subscribe(input: AnyPublisher<Action, Never>) -> AnyPublisher<Event, Never> {
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
        if snapshotRestorableComponent.isMinimumHeight { snapshotRestorableComponent.isMinimumHeight = false }

        if snapshotRestorableComponent.captureState == .needsCapture {
            trackingSnapshot.description = ""
            trackingSnapshot.saveMode = .revert
            trackingSnapshot.makingDate = Date()

            snapshotRestorableComponent.insertTrackingSnapshot(trackingSnapshot: trackingSnapshot)
        }

        snapshotRestorableComponent.revertComponentContentsUsingSnapshot(snapshotID: currentViewedSnapshotID)

        componentSnapshotCoreDataRepository.revertComponentContents(
            modifiedComponent: snapshotRestorableComponent,
            trackingSnapshot: trackingSnapshot
        )
        .receive(on: DispatchQueue.main)
        .sinkToResult { [weak self] _ in
            guard let self else { return }
            updateTrackingSnapshotSignal.send(())
            output.send(.didRestoreSnapshot(snapshotRestorableComponent.componentContents))
        }
        .store(in: &subscriptions)
    }

    private func removeSnapshot(_ tappedSnapshotID: UUID) {
        guard currentViewedSnapshotID == tappedSnapshotID else { return }

        if let targetSnapshotIndex = snapshotRestorableComponent
            .snapshots
            .firstIndex(where: { $0.snapshotID == tappedSnapshotID })
        {
            let nextSnapshotIndex =
                targetSnapshotIndex + 1 <= snapshotRestorableComponent.snapshots.count - 1
                ? targetSnapshotIndex + 1 : targetSnapshotIndex - 1
            let nextSnapshot =
                nextSnapshotIndex < 0
                ? nil : snapshotRestorableComponent.snapshots[nextSnapshotIndex]

            snapshotRestorableComponent.removeSnapshot(at: targetSnapshotIndex)

            componentSnapshotCoreDataRepository.removeSnapshot(
                componentID: snapshotRestorableComponent.id,
                snapshotID: tappedSnapshotID)

            currentViewedSnapshotID = nextSnapshot?.snapshotID
            output.send(.didRemoveSnapshot(nextSnapshot?.getSnapshotMetaData(), targetSnapshotIndex))
        }
    }

    private func updateSnapshotMetaDataWhenScrolled(snapshotViewIndex: Int) {
        let currentViewedSnapshot = snapshotRestorableComponent.snapshots[snapshotViewIndex]
        currentViewedSnapshotID = currentViewedSnapshot.snapshotID
        output.send(.didUpdateSnapshotMetaData(currentViewedSnapshot.getSnapshotMetaData()))
    }

    enum Action {
        case viewDidLoad
        case willRestoreSnapshot
        case willRemoveSnapshot(UUID)
        case willUpdateSnapshotMetaData(Int)
    }

    enum Event {
        case viewDidLoad(any SnapshotRestorablePageComponent)
        case didRestoreSnapshot(Codable)
        case didRemoveSnapshot(SnapshotMetaData?, Int)
        case didUpdateSnapshotMetaData(SnapshotMetaData)
    }
}
