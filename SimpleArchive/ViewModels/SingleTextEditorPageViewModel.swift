import Combine
import UIKit

@MainActor class SingleTextEditorPageViewModel: NSObject, ViewModelType {

    typealias Input = SingleTextEditorPageInput
    typealias Output = SingleTextEditorPageOutput

    private var output = PassthroughSubject<SingleTextEditorPageOutput, Never>()
    private var subscriptions = Set<AnyCancellable>()

    private var coredataReposotory: MemoSingleComponentRepositoryType
    private var textEditorComponent: TextEditorComponent
    private var pageTitle: String

    private let captureDispatchSemaphore = DispatchSemaphore(value: 1)

    init(
        coredataReposotory: MemoSingleComponentRepositoryType,
        textEditorComponent: TextEditorComponent,
        pageTitle: String
    ) {
        self.coredataReposotory = coredataReposotory
        self.textEditorComponent = textEditorComponent
        self.pageTitle = pageTitle

        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(captureComponentsChanges),
            name: UIScene.didEnterBackgroundNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(captureComponentsChanges),
            name: UIScene.didDisconnectNotification,
            object: nil)
    }

    deinit { print("deinit SingleTextEditorPageViewModel") }

    func subscribe(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            guard let self else { return }

            switch event {
                case .viewDidLoad:
                    output.send(
                        .viewDidLoad(
                            pageTitle,
                            textEditorComponent.creationDate,
                            textEditorComponent.componentContents
                        )
                    )

                case .viewWillDisappear:
                    captureComponentsChangesOnDisappear()

                case .willNavigateSnapshotView:
                    guard let repository = DIContainer.shared.resolve(ComponentSnapshotCoreDataRepository.self)
                    else { return }

                    let componentSnapshotViewModel = ComponentSnapshotViewModel(
                        componentSnapshotCoreDataRepository: repository,
                        snapshotRestorableComponent: textEditorComponent)
                    output.send(.didNavigateSnapshotView(componentSnapshotViewModel))

                case .willRestoreComponent:
                    output.send(.didRestoreComponent(textEditorComponent.componentContents))

                case .willCaptureComponent(let desc):
                    coredataReposotory.captureSnapshot(
                        snapshotRestorableComponent: textEditorComponent,
                        saveMode: .manual,
                        snapShotDescription: desc)

                    output.send(.didCompleteComponentCapture)

                case .willEditTextComponent(let detail):
                    textEditorComponent.componentContents = detail
                    textEditorComponent.setCaptureState(to: .needsCapture)
                    coredataReposotory.saveComponentsDetail(modifiedComponent: textEditorComponent)
            }
        }
        .store(in: &subscriptions)

        return output.eraseToAnyPublisher()
    }

    private func captureComponentsChangesOnDisappear() {
        if let changedTextEditorComponent = textEditorComponent.currentIfUnsaved() {
            coredataReposotory.captureSnapshot(snapshotRestorableComponents: [changedTextEditorComponent])
        }
    }

    @objc private func captureComponentsChanges() {
        var taskID: UIBackgroundTaskIdentifier = .invalid

        taskID = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(taskID)
            taskID = .invalid
        }

        captureDispatchSemaphore.wait()

        if let changedTextEditorComponent = textEditorComponent.currentIfUnsaved() {
            coredataReposotory.captureSnapshot(snapshotRestorableComponents: [changedTextEditorComponent])
                .sinkToResult { result in
                    switch result {
                        case .success:
                            print("capture successfully")
                        case .failure(let failure):
                            print("capture fail reason : \(failure.localizedDescription)")
                    }
                    UIApplication.shared.endBackgroundTask(taskID)
                    self.captureDispatchSemaphore.signal()
                }
                .store(in: &subscriptions)
        } else {
            print("no components to capture")
            UIApplication.shared.endBackgroundTask(taskID)
            captureDispatchSemaphore.signal()
        }
    }
}
