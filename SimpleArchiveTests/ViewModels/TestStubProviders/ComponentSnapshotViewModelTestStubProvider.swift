final class ComponentSnapshotViewModelTestStubProvider: TestStubProvidable {
    typealias TargetTestClassType = ComponentSnapshotViewModelTests

    private var stubContainer: [String: any StubDatable] = [:]
    private var recentUsingKey: String = ""

    init() {
        let stubs: [any StubDatable] = [
            RemoveSnapshotWhenFirstSnapshotIsDeletedTestStub(),
            RemoveSnapshotWhenMiddleSnapshotIsDeletedTestStub(),
            RemoveSnapshotWhenLastSnapshotIsDeletedTestStub(),
            RemoveSnapshotWhenOnlySnapshotIsDeletedTestStub(),
            RemoveSnapshotFailureWhenSnapshotMismatchTestStub(),
            RemoveSnapshotFailureWhenNotFoundSnapshotTestStub(),
            RestoreSnapshotSuccessfullyTestStub(),
            RestoreSnapshotFailureWhenNotFoundSnapshotStubTest(),
        ]
        stubs.forEach { stubContainer[$0.testTargetName] = $0 }
    }

    func getStub(with functionName: String = #function) -> any StubDatable {
        recentUsingKey = functionName
        return stubContainer[functionName]!
    }

    func removeUsedStubData() {
        stubContainer.removeValue(forKey: recentUsingKey)
    }
}
