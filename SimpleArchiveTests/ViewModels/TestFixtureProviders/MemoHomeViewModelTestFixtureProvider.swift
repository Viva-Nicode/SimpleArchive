final class MemoHomeViewModelTestFixtureProvider: TestFixtureProvidable {
    typealias TargetTestClassType = MemoHomeViewModelTests

    private var fixtureContainer: [String: any TestFixtureType] = [:]
    private var recentUsingKey: String = ""

    init() {
        let fixtures: [any TestFixtureType] = [
            FetchMemoDataSuccessfullyTestFixture(),
            MoveToPreviousDirectorySuccessfullyTestFixture(),
            FixPageSuccessfullyTestFixture(),
            UnfixPageSuccessfullyTestFixture(),
            CreatedNewDirectorySuccessfullyTestFixture(),
            CreatedNewPageSuccessfullyTestFixture(),
        ]
        fixtures.forEach { fixtureContainer[$0.testTargetName] = $0 }
    }

    func getFixture(with functionName: String = #function) -> any TestFixtureType {
        recentUsingKey = functionName
        return fixtureContainer[functionName]!
    }

    func removeUsedFixtureData() {
        fixtureContainer.removeValue(forKey: recentUsingKey)
    }
}
