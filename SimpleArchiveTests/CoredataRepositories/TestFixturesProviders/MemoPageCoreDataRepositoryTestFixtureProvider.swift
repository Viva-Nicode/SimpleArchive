final class MemoPageCoreDataRepositoryTestFixtureProvider: TestFixtureProvidable {
    typealias TargetTestClassType = MemoPageCoreDataRepositoryTests

    private var FixtureContainer: [String: any TestFixtureType] = [:]
    private var recentUsingKey: String = ""

    init() {
        let fixtures: [any TestFixtureType] = [
            FixPagesSuccessfullyTestFixture(),
            UnfixPagesSuccessfullyTestFixture(),
        ]
        fixtures.forEach { FixtureContainer[$0.testTargetName] = $0 }
    }

    func getFixture(with functionName: String = #function) -> any TestFixtureType {
        recentUsingKey = functionName
        return FixtureContainer[functionName]!
    }

    func removeUsedFixtureData() {
        FixtureContainer.removeValue(forKey: recentUsingKey)
    }
}
