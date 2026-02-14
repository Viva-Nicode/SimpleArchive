import Foundation
import UIKit

enum MemoPageViewInput {
    case viewDidLoad
    case willCreateNewComponent(ComponentType)
    case willRemovePageComponent(componentID: UUID)
    case willChangeComponentOrder(Int, Int)
    case willRenameComponent(componentID: UUID, newName: String)
    case willToggleFoldingComponent(componentID: UUID)
    case willMaximizePageComponent(componentID: UUID)

    // MARK: - Audio
    case willDownloadMusicWithCode(UUID, String)
    case willImportAudioFileFromFileSystem(UUID, [URL])
    case willPlayAudioTrack(UUID, Int)
    case willToggleAudioPlayingState
    case willPlayNextAudioTrack
    case willPlayPreviousAudioTrack
    case willSeekAudioTrack(TimeInterval)
    case willRemoveAudioTrack(UUID, Int)
    case willApplyAudioMetadataChanges(AudioTrackMetadata, UUID, Int)
    case willSortAudioTracks(UUID, AudioTrackSortBy)
    case willMoveAudioTrackOrder(UUID, Int, Int)
}

enum MemoPageViewOutput {
    case viewDidLoad(MemoPageModel, AudioContentsDataContainerType)
    case didAppendComponentAt(Int)
    case didRemovePageComponent(componentIndex: Int)
    case didRenameComponent(componentIndex: Int, newName: String)
    case didToggleFoldingComponent(componentIndex: Int, isMinimized: Bool)
    case didMaximizePageComponent(componentIndex: Int)

    // MARK: - Audio
    case didAppendAudioTrackRows(Int, [Int])
    case didPlayAudioTrack(Int, Int, TimeInterval?, AudioTrackMetadata, AudioWaveformData?)
    case didToggleAudioPlayingState(Int, Int, Bool)
    case didUpdateAudioDownloadProgress(Int, Float)
    case didSeekAudioTrack(Int, Int, TimeInterval, TimeInterval)
    case didRemoveAudioTrack(Int, Int)
    case didRemoveAudioTrackAndPlayNextAudio(Int, Int, Int, TimeInterval?, AudioTrackMetadata, AudioWaveformData?)
    case didRemoveAudioTrackAndStopPlaying(Int, Int)
    case didSortAudioTracks(Int, [String], [String])
    case didPresentInvalidDownloadCode(Int)
    case didApplyAudioMetadataChanges(Int, Int, AudioTrackMetadata, Bool, Int?)
}
