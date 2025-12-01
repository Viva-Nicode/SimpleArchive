final class ComponentSnapshotViewModelTestFixtureProvider: TestFixtureProvidable {
    typealias TargetTestClassType = ComponentSnapshotViewModelTests

    private var fixtureContainer: [String: any TestFixtureType] = [:]
    private var recentUsingKey: String = ""

    init() {
        let fixtures: [any TestFixtureType] = [
            RemoveSnapshotWhenFirstSnapshotIsDeletedTestFixture(),
            RemoveSnapshotWhenMiddleSnapshotIsDeletedTestFixture(),
            RemoveSnapshotWhenLastSnapshotIsDeletedTestFixture(),
            RemoveSnapshotWhenOnlySnapshotIsDeletedTestFixture(),
            RemoveSnapshotFailureWhenSnapshotMismatchTestFixture(),
            RemoveSnapshotFailureWhenNotFoundSnapshotTestFixture(),
            RestoreSnapshotSuccessfullyTestFixture(),
            RestoreSnapshotFailureWhenNotFoundSnapshotTestFixture(),
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
