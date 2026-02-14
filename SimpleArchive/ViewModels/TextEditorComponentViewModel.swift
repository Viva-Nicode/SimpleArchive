import Combine
import Foundation

final class TextEditorComponentViewModel: PageComponentViewModelType {
    var eventOutput = PassthroughSubject<TextEditorComponentViewModelEvent, Never>()
    var subscriptions = Set<AnyCancellable>()

    private var interactor: TextEditorComponentInteractor
    private var title: String
    private var createdDate: Date
    private var contents: String

    init(textEditorComponentInteractor: TextEditorComponentInteractor) {
        self.interactor = textEditorComponentInteractor
        self.title = textEditorComponentInteractor.pageComponent.title
        self.createdDate = textEditorComponentInteractor.pageComponent.creationDate
        self.contents = textEditorComponentInteractor.pageComponent.componentContents
        myLog("\(title)")
    }

    deinit { myLog(String(describing: Swift.type(of: self)), "\(title)", c: .purple) }

    func bindToView(input: AnyPublisher<TextEditorComponentViewModelAction, Never>)
        -> AnyPublisher<TextEditorComponentViewModelEvent, Never>
    {
        input.sink { [weak self] event in
            guard let self else { return }
            switch event {

                case .textEditorComponentAction(let textEditorAction):
                    switch textEditorAction {
                        case .willEditTextComponentContents(let editedText):
                            interactor.saveTextEditorComponentContentsChange(contents: editedText)

                        case .willUndoTextComponentContents:
                            if let undidText = interactor.undoTextEditorComponentContents() {
                                eventOutput.send(
                                    .textEditorComponentEvent(.didUndoTextComponentContents(undidText: undidText)))
                            }
                    }

                case .snapshotAction(let snapshotAction):
                    switch snapshotAction {
                        case .willManualCapturePageComponent(let description):
                            interactor.saveTrackedSnapshotManual(description: description)
                            eventOutput.send(.snapshotEvent(.didManualCapturePageComponent))

                        case .willNavigateComponentSnapshotView:
                            let container = DIContainer.shared
                            container.setArgument(
                                ComponentSnapshotViewModel.self,
                                interactor.pageComponent as any SnapshotRestorablePageComponent)
                            container.setArgument(
                                ComponentSnapshotViewModel.self,
                                interactor.trackingSnapshot as any ComponentSnapshotType)
                            let componentSnapshotViewModel = container.resolve(ComponentSnapshotViewModel.self)

                            componentSnapshotViewModel.updateTrackingSnapshotSignal
                                .sink { [weak self] _ in
                                    guard let self else { return }
                                    interactor.trackingSnapshot = TextEditorComponentSnapshot(
                                        contents: interactor.pageComponent.componentContents,
                                        description: "",
                                        saveMode: .automatic,
                                        modificationHistory: [])
                                }
                                .store(in: &subscriptions)
                            eventOutput.send(
                                .snapshotEvent(.didNavigateComponentSnapshotView(componentSnapshotViewModel)))
                    }
            }
        }
        .store(in: &subscriptions)

        return eventOutput.eraseToAnyPublisher()
    }

    var singleTextEditorComponentViewControllerInitialData: (title: String, createdDate: Date, contents: String) {
        (title, createdDate, contents)
    }
}

extension TextEditorComponentViewModel {
    enum Action {
        case willEditTextComponentContents(editedText: String)
        case willUndoTextComponentContents
    }

    enum Event {
        case didUndoTextComponentContents(undidText: String)
    }
}

enum TextEditorComponentViewModelAction {
    case textEditorComponentAction(TextEditorComponentViewModel.Action)
    case snapshotAction(SnapshotRestorableComponentAction)
}

enum TextEditorComponentViewModelEvent {
    case textEditorComponentEvent(TextEditorComponentViewModel.Event)
    case snapshotEvent(SnapshotRestorableComponentEvent)
}
