import XCTest

protocol FixtureProvidingTestCase {
    associatedtype FixtureType: TestFixtureProvidable where FixtureType.TargetTestClassType == Self
    var fixtureProvider: FixtureType { get }
}

protocol TestFixtureProvidable {
    associatedtype TargetTestClassType: XCTestCase
    func getFixture(with functionName: String) -> any TestFixtureType
    func removeUsedFixtureData()
}
