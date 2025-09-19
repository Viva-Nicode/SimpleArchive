final class MemoPageCoreDataRepositoryTestStubProvider: TestStubProvidable {
    typealias TargetTestClassType = MemoPageCoreDataRepositoryTests

    private var stubContainer: [String: any StubDatable] = [:]
    private var recentUsingKey: String = ""

    init() {
        let stubs: [any StubDatable] = [
            FixPagesSuccessfullyTestStub(),
            UnfixPagesSuccessfullyTestStub(),
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
