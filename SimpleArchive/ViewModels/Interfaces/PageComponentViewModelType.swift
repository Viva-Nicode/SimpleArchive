import Combine
import Foundation

@MainActor protocol PageComponentViewModelType: AnyObject {
    associatedtype Action
    associatedtype Event

    associatedtype ViewModelAction
    associatedtype ViewModelEvent

    var subscriptions: Set<AnyCancellable> { get set }

    func bindToView(input: AnyPublisher<ViewModelAction, Never>) -> AnyPublisher<ViewModelEvent, Never>
    func clearSubscriptions()
}

extension PageComponentViewModelType {
    func clearSubscriptions() { subscriptions.removeAll() }
}
