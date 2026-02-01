import Combine

final class TextEditorComponentViewModel: PageComponentViewModelType {
    private let eventOutput = PassthroughSubject<Event, Never>()
    private var subscriptions = Set<AnyCancellable>()
    private let textEditorComponentInteractor: TextEditorComponentInteractor

    init(textEditorComponentInteractor: TextEditorComponentInteractor) {
        self.textEditorComponentInteractor = textEditorComponentInteractor
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
            }
        }
        .store(in: &subscriptions)

        return eventOutput.eraseToAnyPublisher()
    }

    func clearSubscriptions() {
        subscriptions.removeAll()
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

protocol PageComponentViewModelType: AnyObject {
    associatedtype Action
    associatedtype Event

    func bindToView(input: AnyPublisher<Action, Never>) -> AnyPublisher<Event, Never>
    func clearSubscriptions()
}
