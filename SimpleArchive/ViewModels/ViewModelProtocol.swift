import Combine

@MainActor protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    associatedtype ErrorOutput: Error = Never

    func subscribe(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never>
    func errorSubscribe() -> AnyPublisher<ErrorOutput, Never>
}

extension ViewModelType where ErrorOutput == Never {
    func errorSubscribe() -> AnyPublisher<ErrorOutput, Never> {
        Empty<Never, Never>().eraseToAnyPublisher()
    }
}
