import Combine
import XCTest

extension Publisher {
    func sinkToFulfill<T>(_ exp: XCTestExpectation, _ factual: FactualOutput<T>) -> AnyCancellable {
        sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    XCTFail(error.localizedDescription)
                }
            },
            receiveValue: { value in
                factual.setOutput(value as? T)
                exp.fulfill()
            }
        )
    }
}

extension Publisher where Output == Void {
    func sinkToFulfill(_ exp: XCTestExpectation) -> AnyCancellable {
        sink(
            receiveCompletion: { completion in
                switch completion {
                    case let .failure(error):
                        XCTFail(error.localizedDescription)
                    default: break
                }
            },
            receiveValue: { value in
                exp.fulfill()
            }
        )
    }
}

final class FactualOutput<T> {

    private var output: T?

    func setOutput(_ output: T?) {
        self.output = output
    }

    func getOutput() throws -> T {
        switch output {
            case .none:
                throw TestError.outputIsNil

            case .some(let unwrappedOutput):
                return unwrappedOutput
        }
    }

    enum TestError: Error {
        case outputIsNil
    }
}

extension Result {
    func publish() -> AnyPublisher<Success, Failure> {
        return publisher.publish()
    }
}

extension Publisher {
    func publish() -> AnyPublisher<Output, Failure> {
        delay(for: .milliseconds(10), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}
