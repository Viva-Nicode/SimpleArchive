import Foundation
import UIKit

enum MemoPageViewInput {
    case viewDidLoad
    case createNewComponent(ComponentType)
    case minimizeComponent(UUID)
    case maximizeComponent(UUID)
    case removeComponent(UUID)
    case changeComponentName(UUID, String)
    case changeComponentOrder(Int, Int)
    case tappedSnapshotButton(UUID)
    case tappedCaptureButton(UUID, String)
    // MARK: - Table
    case appendTableComponentRow(UUID)
    case removeTableComponentRow(UUID, UUID)
    case appendTableComponentColumn(UUID)
    case editTableComponentColumn(UUID, [TableComponentColumn])
    case editTableComponentCellValue(UUID, UUID, String)
    case presentTableComponentColumnEditPopupView(UUID, Int)
    // MARK: - Audio
//    case willStoreAudioComponentDataSource(UUID, AudioComponentDataSource)
    case willDownloadMusicWithCode(UUID, String)
    case willPlayAudioTrack(UUID, Int)
    case willTapPlayPauseButton
    case willPlayNextAudioTrack
    case willPlayPreviousAudioTrack
    case willSeekAudioTrack(TimeInterval)
    case willPresentGallery(UIImageView)
    case willRemoveAudioTrack(UUID, Int)
    case willEditAudioTrackMetadata(AudioTrackMetadata, UUID, Int)
    case willSortAudioTracks(UUID, AudioTrackSortBy)
    case willPresentFilePicker(UUID)
    case willDropAudioTrack(UUID, Int, Int)
    case viewWillDisappear
}

enum MemoPageViewOutput {
    case viewDidLoad(String)
    case insertNewComponentAtLastIndex(Int)
    case removeComponentAtIndex(Int)
    case maximizeComponent(any PageComponent, Int)
    case didTappedSnapshotButton(ComponentSnapshotViewModel, Int)
    case didMinimizeComponentHeight(Int, Bool)
    // MARK: - Table
    case didAppendTableComponentRow(Int, TableComponentRow)
    case didRemoveTableComponentRow(Int, Int)
    case didAppendTableComponentColumn(Int, (TableComponentColumn, [TableComponentCell]))
    case didEditTableComponentCellValue(Int, Int, Int, String)
    case didPresentTableComponentColumnEditPopupView([TableComponentColumn], Int, UUID)
    case didEditTableComponentColumn(Int, [TableComponentColumn])
    // MARK: - Audio
    case didDownloadMusicWithCode(Int, [Int])
    case didPlayAudioTrack(Int?, Int, URL, Int, TimeInterval?, AudioTrackMetadata, AudioSampleData?)
    case didTapPlayPauseButton(Int, Int, Bool, TimeInterval?)
    case updateAudioDownloadProgress(Int, Float)
    case didSeekAudioTrack(Int, Int, TimeInterval, TimeInterval?)
    case didPresentGallery(UIImageView)
    case didRemoveAudioTrack(Int, Int)
    case didSortAudioTracks(Int, [String], [String])
    case presentInvalidDownloadCode(Int)
    case outOfSongs(Int)
    case didPresentFilePicker
    case didEditAudioTrackMetadata(Int, Int, AudioTrackMetadata, Bool, Int?)
}
