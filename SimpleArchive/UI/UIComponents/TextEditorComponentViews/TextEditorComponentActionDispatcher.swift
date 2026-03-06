import Combine
import Foundation

protocol TextEditorComponentActionDispatcherType: PageComponentActionDispatcherType
where EHT == TextEditorComponentViewEventHandler, VMT == TextEditorComponentViewModel {}

final class TextEditorComponentActionDispatcher: TextEditorComponentActionDispatcherType {

    typealias Action = TextEditorComponentViewModelAction
    typealias Event = TextEditorComponentViewModelEvent

    private let dispatcher = PassthroughSubject<Action, Never>()
    private var subscriptions = Set<AnyCancellable>()
    private var viewModel: TextEditorComponentViewModel?

    func bindToViewModel(
        viewModel: TextEditorComponentViewModel,
        UIEventHandler: TextEditorComponentViewEventHandler
    ) {
        self.viewModel = viewModel
        self.viewModel?
            .bindToView(input: dispatcher.eraseToAnyPublisher())
            .sink { UIEventHandler.UIupdateEventHandler($0) }
            .store(in: &subscriptions)
    }

    func saveTextEditorComponentContentsChanged(contents: String) {
        dispatcher.send(.textEditorComponentAction(.willEditTextComponentContents(editedText: contents)))
    }

    func undoTextEditorComponentContents() {
        dispatcher.send(.textEditorComponentAction(.willUndoTextComponentContents))
    }

    func captureComponentManual(description: String) {
        dispatcher.send(.snapshotAction(.willManualCapturePageComponent(description: description)))
    }

    func navigateComponentSnapshotView() {
        dispatcher.send(.snapshotAction(.willNavigateComponentSnapshotView))
    }

    func clearSubscriptions() {
        subscriptions.removeAll()
        viewModel?.clearSubscriptions()
        viewModel = nil
    }
}
