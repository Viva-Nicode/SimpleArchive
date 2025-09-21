import Combine
import XCTest

@testable import SimpleArchive

final class MockComponentFactory: Mock, ComponentFactoryType {

    enum Action: Equatable {
        case setCreator
        case createComponent
    }

    var actions = MockActions<Action>(expected: [])
    var createComponentResult: (any PageComponent)!

    func setCreator(creator: any ComponentCreatorType) {
        register(.setCreator)
    }

    func createComponent() -> any PageComponent {
        register(.createComponent)
        return createComponentResult
    }

}
