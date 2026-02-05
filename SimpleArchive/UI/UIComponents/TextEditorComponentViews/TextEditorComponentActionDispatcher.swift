import Combine
import Foundation

final class TextEditorComponentActionDispatcher {
    typealias Input = TextEditorComponentViewModel.Action
    typealias Output = TextEditorComponentViewModel.Event

    private let dispatcher = PassthroughSubject<Input, Never>()
    private var subscriptions = Set<AnyCancellable>()

    func saveTextEditorComponentContentsChanged(contents: String) {
        dispatcher.send(.willEditTextComponentContents(editedText: contents))
    }

    func undoTextEditorComponentContents() {
        dispatcher.send(.willUndoTextComponentContents)
    }
    
    func captureTextEditorComponentManual(snapshotDescription: String) {
        dispatcher.send(.willCaptureManualTextComponent(description: snapshotDescription))
    }
    
    func captureTextEditorComponentAutomatic(){
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
    
    func maximizePageComponent(){
        dispatcher.send(.willMaximizePageComponent)
    }

    func bindToViewModel(viewModel: TextEditorComponentViewModel, updateUIWithEvent: @escaping (Output) -> Void) {
        viewModel
            .bindToView(input: dispatcher.eraseToAnyPublisher())
            .sink { updateUIWithEvent($0) }
            .store(in: &subscriptions)
    }

    func clearSubscriptions() {
        subscriptions.removeAll()
    }
}
