import Foundation
import UIKit

enum SingleAudioPageInput {
    case viewDidLoad
    case viewWillDisappear

    case willDownloadMusicWithCode(String)
    case willImportAudioFilesFromFileSystem([URL])
    case willPlayAudioTrack(Int)
    case willApplyAudioMetadataChanges(AudioTrackMetadata, Int)
    case willSortAudioTracks(AudioTrackSortBy)
    case willRemoveAudioTrack(Int)
    case willMoveAudioTrackOrder(Int, Int)
    case willPlayNextAudioTrack
    case willPlayPreviousAudioTrack
    case willToggleAudioPlayingState
    case willSeekAudioTrack(TimeInterval)
}

enum SingleAudioPageOutput {
    case viewDidLoad(String, AudioComponent, AudioComponentDataSource)
    
    case didAppendAudioTrackRows([Int])
    case didPlayAudioTrack(Int, TimeInterval?, AudioTrackMetadata, AudioSampleData?)
    case didApplyAudioMetadataChanges(Int, AudioTrackMetadata, Bool, Int?)
    case didToggleAudioPlayingState(Bool, Int?)
    case didUpdateAudioDownloadProgress(Float)
    case didSeekAudioTrack(TimeInterval, TimeInterval?, Int?)
    case didSortAudioTracks([String], [String])
    case didRemoveAudioTrack(Int)
    case didRemoveAudioTrackAndPlayNextAudio(Int, Int, TimeInterval?, AudioTrackMetadata, AudioSampleData?)
    case didPresentInvalidDownloadCode
    case didRemoveAudioTrackAndStopPlaying(Int)
}
