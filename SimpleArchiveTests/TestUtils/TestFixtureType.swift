import Foundation

@testable import SimpleArchive

protocol TestFixtureType: AnyObject {
    typealias NoUsed = Void
    
    associatedtype GivenFixtureDataType
    associatedtype TestTargetInputType
    associatedtype ExpectedOutputType

    var testTargetName: String { get }
    func getFixtureData() -> Any
}

enum TestDataProvideState {
    case givenFixtureData
    case testTargetInput
    case testVerifyOutput
    case allDataConsumed
}

//open class testStub<G, W, T> {
//
//    var testTargetName: String = ""
//    var givenData: G = "" as! G
//
//    func given(_ given: (G) -> Void) {
//
//    }
//
//    func when(_ when: (W) -> Void) {
//
//    }
//}
