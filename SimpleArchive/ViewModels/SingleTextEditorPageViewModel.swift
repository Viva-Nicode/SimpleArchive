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
            selector: #selector(saveComponentsChanges),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
    }

    deinit { print("deinit SingleTextEditorPageViewModel") }

    func subscribe(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            guard let self else { return }

            switch event {
                case .viewDidLoad(let subject):
                    textEditorComponent
                        .assignDetail(subject: subject)
                        .store(in: &subscriptions)
                    output.send(
                        .viewDidLoad(
                            pageTitle,
                            textEditorComponent.creationDate,
                            textEditorComponent.detail))

                case .viewWillDisappear:
                    saveComponentsChanges()

                case .willPresentSnapshotView:
                    guard let repository = DIContainer.shared.resolve(ComponentSnapshotCoreDataRepository.self)
                    else { return }

                    let componentSnapshotViewModel = ComponentSnapshotViewModel(
                        componentSnapshotCoreDataRepository: repository,
                        snapshotRestorableComponent: textEditorComponent as (any SnapshotRestorable))

                    output.send(.didTappedSnapshotButton(componentSnapshotViewModel))

                case .willRestoreComponentWithSnapshot:
                    output.send(.didTappedCaptureButton(textEditorComponent.detail))

                case .willCaptureToComponent(let desc):
                    coredataReposotory.captureSnapshot(
                        snapshotRestorableComponent: textEditorComponent,
                        desc: desc)
            }
        }
        .store(in: &subscriptions)

        return output.eraseToAnyPublisher()
    }

    @objc private func saveComponentsChanges() {
        if let changedTextEditorComponent = textEditorComponent.currentIfUnsaved() {
            coredataReposotory.saveComponentsDetail(changedComponents: [changedTextEditorComponent])
        }
    }
}
