import Foundation

@testable import SimpleArchive

final class UpdateAudioComponentContentChangesWithAppendAudiosSuccessfullyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = MemoDirectoryModel
    typealias TestTargetInputType = AudioComponent
    typealias ExpectedOutputType = (Int, [(Int, UUID)])

    let testTargetName = "test_updateAudioComponentContentChanges_withAppendAudios_successfully()"
    private var provideState: TestDataProvideState = .givenFixtureData

    private var testDirectory: MemoDirectoryModel!
    private var audioComponent: AudioComponent!
    private var insertedAudioTracks: [AudioTrack] = []
    private var appendedIndices: [Int] = []

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                insertedAudioTracks = [
                    AudioTrack(title: "b audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
                    AudioTrack(title: "d audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
                    AudioTrack(title: "f audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
                    AudioTrack(title: "h audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
                    AudioTrack(title: "j audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
                ]
                appendedIndices = audioComponent.addAudios(audiotracks: insertedAudioTracks)
                audioComponent.actions.append(
                    .appendAudio(appendedIndices: appendedIndices, tracks: insertedAudioTracks))
                return audioComponent!

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return (10, Array(zip(appendedIndices, insertedAudioTracks.map { $0.id })))

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
        testDirectory = MemoDirectoryModel(name: "Test Directory")
        let testPage = MemoPageModel(name: "Test Page", parentDirectory: testDirectory)

        audioComponent = AudioComponent()
        audioComponent.componentContents.sortBy = .name
        let tracks: [AudioTrack] = [
            AudioTrack(title: "a audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "c audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "e audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "g audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "i audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
        ]
        _ = audioComponent.componentContents.addAudios(audiotracks: tracks)
        testPage.appendChildComponent(component: audioComponent)

        return testDirectory
    }
}
