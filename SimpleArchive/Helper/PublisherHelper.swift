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

extension Publisher where Output: Sequence {
    func mapEnumerated<T>(_ transform: @escaping (Int, Self.Output.Element) -> T) -> Publishers.Map<Self, [T]> {
        self.map { value in
            value.enumerated()
                .map { i, v in
                    transform(i, v)
                }
        }
    }
    
    func tryMapEnumerated<T>(
        _ transform: @escaping (Int, Output.Element) throws -> T
    ) -> Publishers.TryMap<Self, [T]> {
        self.tryMap { sequence in
            try sequence.enumerated()
                .map { index, element in
                    try transform(index, element)
                }
        }
    }
}
