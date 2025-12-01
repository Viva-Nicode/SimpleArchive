final class MemoComponentCoreDataRepositoryTestFixtureProvider: TestFixtureProvidable {
    
    typealias TargetTestClassType = MemoComponentCoreDataRepositoryTests

    private var fixtureContainer: [String: any TestFixtureType] = [:]
    private var recentUsingKey: String = ""

    init() {
        let fixtures: [any TestFixtureType] = [
            CreateComponentSuccessfullyTestFixture(),
            SaveComponentDetailSuccessfullyTestFixture(),
            SaveComponentDetailWithRestoredComponentsSuccessfullyTestFixture(),
            UpdateComponentChangesSuccessfullyTestFixture(),
            CaptureSnapshotSuccessfullyTestFixture(),
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
