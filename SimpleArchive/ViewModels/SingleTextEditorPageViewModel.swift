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
                        snapShotDescription: desc)

                    output.send(.didCompleteComponentCapture)

                case .willEditTextComponent(let contents):
                    let action = makeTextEditActionFromContentsDiff(
                        originContents: textEditorComponent.componentContents,
                        editedContents: contents)
                    textEditorComponent.componentContents = contents
                    textEditorComponent.setCaptureState(to: .needsCapture)
                    textEditorComponent.actions.append(action)
                    coredataReposotory.updateComponentContentChanges(modifiedComponent: textEditorComponent)

                case .willUndoTextComponentContents:
                    guard let action = textEditorComponent.actions.popLast() else { return }
                    let currentContents = textEditorComponent.componentContents
                    let undidText = undoingText(action: action, contents: currentContents)

                    textEditorComponent.componentContents = undidText
                    coredataReposotory.updateComponentContentChanges(modifiedComponent: textEditorComponent)
                    output.send(.didUndoTextComponentContents(undidText))
            }
        }
        .store(in: &subscriptions)

        return output.eraseToAnyPublisher()
    }

    private func makeTextEditActionFromContentsDiff(originContents: String, editedContents: String)
        -> TextEditorComponentAction
    {
        let originChars = Array(originContents)
        let editedChars = Array(editedContents)

        var prefix = 0
        while prefix < min(originChars.count, editedChars.count),
            originChars[prefix] == editedChars[prefix]
        {
            prefix += 1
        }

        var suffix = 0
        while suffix < min(originChars.count - prefix, editedChars.count - prefix),
            originChars[originChars.count - 1 - suffix] == editedChars[editedChars.count - 1 - suffix]
        {
            suffix += 1
        }

        let oldRange = prefix..<(originChars.count - suffix)
        let newRange = prefix..<(editedChars.count - suffix)

        let removedText = String(originChars[oldRange])
        let insertedText = String(editedChars[newRange])

        if removedText.isEmpty, !insertedText.isEmpty {
            return .insert(range: prefix..<prefix, text: insertedText)
        } else {
            return .replace(range: oldRange, from: removedText, to: insertedText)
        }
    }

    private func undoingText(action: TextEditorComponentAction, contents: String) -> String {
        switch action {
            case let .insert(range, insertedText):
                let start = contents.index(contents.startIndex, offsetBy: range.lowerBound)
                let end = contents.index(start, offsetBy: insertedText.count)

                return contents.replacingCharacters(in: start..<end, with: "")

            case let .replace(range, fromText, toText):
                let start = contents.index(contents.startIndex, offsetBy: range.lowerBound)
                let end = contents.index(start, offsetBy: toText.count)

                return contents.replacingCharacters(in: start..<end, with: fromText)
        }
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
