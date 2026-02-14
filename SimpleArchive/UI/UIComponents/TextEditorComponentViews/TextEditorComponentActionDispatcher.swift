import Combine
import Foundation

@MainActor
final class TextEditorComponentActionDispatcher {
    typealias Input = TextEditorComponentViewModelAction
    typealias Output = TextEditorComponentViewModelEvent

    private let dispatcher = PassthroughSubject<Input, Never>()
    private var subscriptions = Set<AnyCancellable>()
    private var viewModel: TextEditorComponentViewModel?

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

    func bindToViewModel(viewModel: any PageComponentViewModelType, updateUIWithEvent: @escaping (Output) -> Void) {
        self.viewModel = viewModel as? TextEditorComponentViewModel
        self.viewModel?
            .bindToView(input: dispatcher.eraseToAnyPublisher())
            .sink { updateUIWithEvent($0) }
            .store(in: &subscriptions)
    }

    func clearSubscriptions() {
        subscriptions.removeAll()
        viewModel?.clearSubscriptions()
        viewModel = nil
    }
}
