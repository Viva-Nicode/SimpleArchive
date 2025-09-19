import Combine

protocol ViewControllerType {

    associatedtype Input
    associatedtype ViewModel: ViewModelType where ViewModel.Input == Input

    var input: PassthroughSubject<Input, Never> { get set }
    var viewModel: ViewModel { get set }
    var subscriptions: Set<AnyCancellable> { get set }

    func bind()
    func handleError()
}

extension ViewControllerType where Self.ViewModel.ErrorOutput == Never {
    func handleError() { }
}
