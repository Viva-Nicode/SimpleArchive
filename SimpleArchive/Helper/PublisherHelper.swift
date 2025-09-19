import Combine
import Foundation

extension Publisher {
    func sinkToResult(_ result: @escaping (Result<Output, Failure>) -> Void) -> AnyCancellable {
        return sink(
            receiveCompletion: { completion in
                switch completion {
                    case let .failure(error):
                        result(.failure(error))
                    default: break
                }
            },
            receiveValue: { value in
                result(.success(value))
            }
        )
    }
}

extension Just where Output == Void {
    static func withErrorType<E>(_ errorType: E.Type) -> AnyPublisher<Void, E> {
        return Just(())
            .setFailureType(to: E.self)
            .eraseToAnyPublisher()
    }
}
