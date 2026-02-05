import Combine
import Foundation

final class TextEditorComponentViewModel: PageComponentViewModelType {
    private let eventOutput = PassthroughSubject<Event, Never>()
    private var subscriptions = Set<AnyCancellable>()
    private let textEditorComponentInteractor: TextEditorComponentInteractor

    private var title: String
    private var createdDate: Date
    private var contents: String

    init(textEditorComponentInteractor: TextEditorComponentInteractor) {
        self.textEditorComponentInteractor = textEditorComponentInteractor
        self.title = textEditorComponentInteractor.pageComponent.title
        self.createdDate = textEditorComponentInteractor.pageComponent.creationDate
        self.contents = textEditorComponentInteractor.pageComponent.componentContents
    }

    func bindToView(input: AnyPublisher<Action, Never>) -> AnyPublisher<Event, Never> {
        input.sink { [weak self] event in
            guard let self else { return }
            switch event {
                case .willEditTextComponentContents(let editedText):
                    textEditorComponentInteractor.saveTextEditorComponentContentsChange(contents: editedText)

                case .willUndoTextComponentContents:
                    if let undidText = textEditorComponentInteractor.undoTextEditorComponentContents() {
                        eventOutput.send(.didUndoTextComponentContents(undidText: undidText))
                    }

                case .willCaptureManualTextComponent(let description):
                    textEditorComponentInteractor.captureSnapshotManual(description: description)
                    eventOutput.send(.didCaptureWithManual)

                case .willRestoreComponentContents:
                    let contents = textEditorComponentInteractor.pageComponentContents
                    eventOutput.send(.didRestoreComponentContents(contents: contents))

                case .willNavigateSnapshotView:
                    let container = DIContainer.shared
                    container.setArgument(
                        ComponentSnapshotViewModel.self,
                        textEditorComponentInteractor.pageComponent as (any SnapshotRestorablePageComponent))
                    let componentSnapshotViewModel = container.resolve(ComponentSnapshotViewModel.self)
                    eventOutput.send(.didNavigateSnapshotView(vm: componentSnapshotViewModel))

                case .wiilRenameComponent(let newName):
                    textEditorComponentInteractor.renamePageComponent(title: newName)
                    eventOutput.send(.didRenameComponent(newName: newName))

                case .willToggleFoldingComponent:
                    let isMinimized = textEditorComponentInteractor.toggleFoldingPageComponent()
                    eventOutput.send(.didToggleFoldingComponent(isMinimized: isMinimized))

                case .willRemovePageComponent:
                    textEditorComponentInteractor.removePageComponent()
                    eventOutput.send(.didRemovePageComponent)

                case .willMaximizePageComponent:
                    let isMaximized = textEditorComponentInteractor.maximizePageComponent()
                    eventOutput.send(
                        isMaximized ? .didMaximizePageComponent : .didToggleFoldingComponent(isMinimized: false))

                case .willCaptureAutomaticTextComponent:
                    textEditorComponentInteractor.captureSnapshotAutomatic()
            }
        }
        .store(in: &subscriptions)

        return eventOutput.eraseToAnyPublisher()
    }

    var singleTextEditorComponentViewControllerInitialData: (String, Date, String) {
        (title: title, createdDate: createdDate, contents: contents)
    }

    func clearSubscriptions() {
        subscriptions.removeAll()
    }
}

extension TextEditorComponentViewModel {
    enum Action {
        // MARK: - Contents
        case willEditTextComponentContents(editedText: String)
        case willUndoTextComponentContents

        // MARK: - Capture & Snapshot
        case willCaptureManualTextComponent(description: String)
        case willCaptureAutomaticTextComponent
        case willRestoreComponentContents
        case willNavigateSnapshotView

        // MARK: - State
        case wiilRenameComponent(newName: String)
        case willToggleFoldingComponent
        case willRemovePageComponent
        case willMaximizePageComponent
    }

    enum Event {
        // MARK: - Contents
        case didUndoTextComponentContents(undidText: String)

        // MARK: - Capture & Snapshot
        case didCaptureWithManual
        case didNavigateSnapshotView(vm: ComponentSnapshotViewModel)
        case didRestoreComponentContents(contents: String)

        // MARK: - State
        case didRenameComponent(newName: String)
        case didToggleFoldingComponent(isMinimized: Bool)
        case didRemovePageComponent
        case didMaximizePageComponent
    }
}

protocol PageComponentViewModelType: AnyObject {
    associatedtype Action
    associatedtype Event

    func bindToView(input: AnyPublisher<Action, Never>) -> AnyPublisher<Event, Never>
    func clearSubscriptions()
}
