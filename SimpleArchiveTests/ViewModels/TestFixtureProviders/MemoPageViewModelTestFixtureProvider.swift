final class MemoPageViewModelTestFixtureProvider: TestFixtureProvidable {
    typealias TargetTestClassType = MemoPageViewModelTests

    private var fixtureContainer: [String: any TestFixtureType] = [:]
    private var recentUsingKey: String = ""

    init() {
        let fixtures: [any TestFixtureType] = [
            CreateNewComponentSuccessfullyTestFixture(),
            CaptureComponentSuccessfullyTestFixture(),
            RemoveComponentSuccessfullyTestFixture(),
            DownloadAudioTracksSuccessfullyTestFixture(),
            DownloadAudiofileWithCodeFailureWhenInvalidCodeTestFixture(),
            ImportAudioFromLocalFileSystemSuccessfulllyTestFixture(),
            PlayAudioTrackSuccessfulllyTestFixture(),
            PlayAudioTrackSuccessfulllyWhenTrackIsAlreadyPlayingTestFixture(),
            ApplyAudioMetadataChangesWhenEditingCurrentlyPlayingTrackTestFixture(),
            RemoveAudioTrackWhenRemovingCurrentlyPlayingAudioTestFixture(),
            RemoveAudioTrackWhenRemovingAudioIsPauseTestFixture(),
            RemoveAudioTrackWhenLastAudioIsPlayingTestFixture(),
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
