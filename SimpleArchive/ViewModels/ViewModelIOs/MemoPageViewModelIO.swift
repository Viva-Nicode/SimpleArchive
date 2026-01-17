import Foundation
import UIKit

enum MemoPageViewInput {
    // MARK: - Life Cycle
    case viewDidLoad
    case viewWillDisappear

    // MARK: - Common
    case willCreateNewComponent(ComponentType)
    case willToggleComponentSize(UUID)
    case willMaximizeComponent(UUID)
    case willRemoveComponent(UUID)
    case willChangeComponentName(UUID, String)
    case willChangeComponentOrder(Int, Int)
    case willNavigateSnapshotView(UUID)
    case willCaptureComponent(UUID, String)

    // MARK: - Text
    case willEditTextComponent(UUID, String)
    case willUndoTextComponentContents(UUID)

    // MARK: - Table
    case willAppendRowToTable(UUID)
    case willRemoveRowToTable(UUID, UUID)
    case willAppendColumnToTable(UUID)
    case willApplyTableColumnChanges(UUID, [TableComponentColumn])
    case willApplyTableCellChanges(UUID, UUID, UUID, String)
    case willPresentTableColumnEditingPopupView(UUID, UUID)

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
    case viewDidLoad(MemoPageModel, AudioContentsDataContainer)

    // MARK: - Common
    case didAppendComponentAt(Int)
    case didRemoveComponentAt(Int)
    case didMaximizeComponent(any PageComponent, Int)
    case didToggleComponentSize(Int, Bool)
    case didNavigateSnapshotView(ComponentSnapshotViewModel, Int)
    case didCompleteComponentCapture(Int)

    // MARK: - Text
    case didUndoTextComponentContents(Int, String)

    // MARK: - Table
    case didAppendRowToTableView(Int, TableComponentRow)
    case didRemoveRowToTableView(Int, Int)
    case didAppendColumnToTableView(Int, TableComponentColumn)
    case didApplyTableCellValueChanges(Int, Int, Int, String)
    case didPresentTableColumnEditPopupView([TableComponentColumn], Int, UUID)
    case didApplyTableColumnChanges(Int, [TableComponentColumn])

    // MARK: - Audio
    case didAppendAudioTrackRows(Int, [Int])
    case didPlayAudioTrack(UUID, Int, UUID, Int, TimeInterval?, AudioTrackMetadata, AudioWaveformData?)
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
