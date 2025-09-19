import XCTest

protocol StubProvidingTestCase {
    associatedtype StubType: TestStubProvidable where StubType.TargetTestClassType == Self
    var stubProvider: StubType { get }
}

protocol TestStubProvidable {
    associatedtype TargetTestClassType: XCTestCase
    func getStub(with functionName: String) -> any StubDatable
    func removeUsedStubData()
}
