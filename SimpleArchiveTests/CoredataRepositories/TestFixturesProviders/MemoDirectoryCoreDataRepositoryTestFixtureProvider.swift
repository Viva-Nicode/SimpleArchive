final class MemoDirectoryCoreDataRepositoryTestFixtureProvider: TestFixtureProvidable {
    typealias TargetTestClassType = MemoDirectoryCoreDataRepositoryTests

    private var fixtureContainer: [String: any TestFixtureType] = [:]
    private var recentUsingKey: String = ""

    init() {
        let fixtures: [any TestFixtureType] = [
            FetchSystemDirectoryEntitiesOnFirstAppLaunchTestFixture(),
            FetchSystemDirectoryEntitiesSuccessfullyTestFixture(),
            CreateStorageItemWithDirectoryTestFixture(),
            CreateStorageItemWithPageTestFixture(),
            MoveFileToDormantBoxWithDirectoryTestFixture(),
            MoveFileToDormantBoxWithPageTestFixture(),
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
