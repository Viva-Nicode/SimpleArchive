import Foundation
import UIKit

enum SingleAudioPageInput {
    case viewDidLoad
    case viewWillDisappear
    case willDownloadMusicWithCode(String)
    case willPlayAudioTrack(Int)
    case willPresentGallery(UIImageView)
    case willEditAudioTrackMetadata(AudioTrackMetadata, Int)
    case willSortAudioTracks(AudioTrackSortBy)
    case willRemoveAudioTrack(Int)
    case willDropAudioTrack(Int, Int)
    case willPlayNextAudioTrack
    case willPlayPreviousAudioTrack
    case willTapPlayPauseButton
    case willSeekAudioTrack(TimeInterval)
}

enum SingleAudioPageOutput {
    case viewDidLoad(String, AudioComponent, AudioComponentDataSource)
    case presentInvalidDownloadCode
    case didDownloadMusicWithCode([Int])
    case didPlayAudioTrack(URL, Int, TimeInterval?, AudioTrackMetadata, AudioSampleData?)
    case didPresentGallery(UIImageView)
    case didEditAudioTrackMetadata(Int, AudioTrackMetadata, Bool, Int?)
    case didTapPlayPauseButton(Bool, Int?, TimeInterval?)
    case updateAudioDownloadProgress(Float)
    case didSeekAudioTrack(TimeInterval, TimeInterval?, Int?)
    case didSortAudioTracks([String], [String])
    case didRemoveAudioTrack(Int)
    case outOfSongs
}
