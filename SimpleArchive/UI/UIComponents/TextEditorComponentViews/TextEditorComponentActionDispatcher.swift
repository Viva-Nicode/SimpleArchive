import Combine
import Foundation

final class TextEditorComponentActionDispatcher {
    typealias Input = TextEditorComponentViewModel.Action
    typealias Output = TextEditorComponentViewModel.Event

    private let dispatcher = PassthroughSubject<Input, Never>()
    private var subscriptions = Set<AnyCancellable>()
    // 뷰와 뷰모델간의 상호작용을 디스패쳐를 통해서만 가능하도록 강제하려고 뷰모델을 디스패쳐에 숨김.
    private var viewModel: TextEditorComponentViewModel?

    func saveTextEditorComponentContentsChanged(contents: String) {
        dispatcher.send(.willEditTextComponentContents(editedText: contents))
    }

    func undoTextEditorComponentContents() {
        dispatcher.send(.willUndoTextComponentContents)
    }

    func captureTextEditorComponentManual(snapshotDescription: String) {
        dispatcher.send(.willCaptureManualTextComponent(description: snapshotDescription))
    }

    func captureTextEditorComponentAutomatic() {
        dispatcher.send(.willCaptureAutomaticTextComponent)
    }

    func navigateToSnapshotView() {
        dispatcher.send(.willNavigateSnapshotView)
    }

    func resotreComponentContents() {
        dispatcher.send(.willRestoreComponentContents)
    }

    func renamePageComponent(newName: String) {
        dispatcher.send(.wiilRenameComponent(newName: newName))
    }

    func foldPageComponent() {
        dispatcher.send(.willToggleFoldingComponent)
    }

    func removePageComponent() {
        dispatcher.send(.willRemovePageComponent)
    }

    func maximizePageComponent() {
        dispatcher.send(.willMaximizePageComponent)
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
