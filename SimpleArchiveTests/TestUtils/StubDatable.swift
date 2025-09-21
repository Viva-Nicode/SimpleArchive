import Foundation

@testable import SimpleArchive

protocol StubDatable: AnyObject {
    associatedtype GivenStubDataType
    associatedtype TestTargetInputType
    associatedtype ExpectedOutputType

    var testTargetName: String { get }
    func getStubData() -> Any
}

extension StubDatable {
    typealias NoUsed = Void
}

enum TestDataProvideState {
    case givenStubData
    case testTargetInput
    case testVerifyOutput
    case allDataConsumed
}

open class testStub<G, W, T> {

    var testTargetName: String = ""
    var givenData: G = "" as! G

    func given(_ given: (G) -> Void) {

    }

    func when(_ when: (W) -> Void) {

    }
}
