import Combine

final class TextEditorComponentActionDispatcher {
    typealias Input = TextEditorComponentViewModel.Action
    typealias Output = TextEditorComponentViewModel.Event

    private let dispatcher = PassthroughSubject<Input, Never>()
    private var subscriptions = Set<AnyCancellable>()

    func saveTextEditorComponentChanged(contents: String) {
        dispatcher.send(.willEditTextComponentContents(editedText: contents))
    }

    func undoTextEditorComponentContents() {
        dispatcher.send(.willUndoTextComponentContents)
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
