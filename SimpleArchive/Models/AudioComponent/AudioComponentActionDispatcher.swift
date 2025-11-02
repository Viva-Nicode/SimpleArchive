import Combine
import Foundation
import UIKit

protocol AudioComponentActionDispatcher {
    func downloadMusics(componentID: UUID, with code: String)
    func playAudioTrack(componentID: UUID, with trackIndex: Int)
    func togglePlayingState()
    func playNextAudioTrack()
    func playPreviousAudioTrack()
    func seekAudioTrack(seek: TimeInterval)
    func changeAudioTrackMetadata(editMetadata: AudioTrackMetadata, componentID: UUID, trackIndex: Int)
    func presentGallery(_ imageView: UIImageView)
    func changeSortByAudioTracks(componentID: UUID, sortBy: AudioTrackSortBy)
    func dropAudioTrack(componentID: UUID, src: Int, des: Int)
    func removeAudioTrack(componentID: UUID, trackIndex: Int)
    func storeDataSource(componentID: UUID, datasource: AudioComponentDataSource)
}

final class MemoPageAudioComponentActionDispatcher: AudioComponentActionDispatcher {

    private let subject: PassthroughSubject<MemoPageViewInput, Never>

    init(subject: PassthroughSubject<MemoPageViewInput, Never>) {
        self.subject = subject
    }

    func downloadMusics(componentID: UUID, with code: String) {
        subject.send(.willDownloadMusicWithCode(componentID, code))
    }

    func playAudioTrack(componentID: UUID, with trackIndex: Int) {
        subject.send(.willPlayAudioTrack(componentID, trackIndex))
    }

    func togglePlayingState() {
        subject.send(.willTapPlayPauseButton)
    }

    func playNextAudioTrack() {
        subject.send(.willPlayNextAudioTrack)
    }

    func playPreviousAudioTrack() {
        subject.send(.willPlayPreviousAudioTrack)
    }

    func seekAudioTrack(seek: TimeInterval) {
        subject.send(.willSeekAudioTrack(seek))
    }

    func changeAudioTrackMetadata(editMetadata: AudioTrackMetadata, componentID: UUID, trackIndex: Int) {
        subject.send(.willEditAudioTrackMetadata(editMetadata, componentID, trackIndex))
    }

    func presentGallery(_ imageView: UIImageView) {
        subject.send(.willPresentGallery(imageView))
    }

    func changeSortByAudioTracks(componentID: UUID, sortBy: AudioTrackSortBy) {
        subject.send(.willSortAudioTracks(componentID, sortBy))
    }

    func dropAudioTrack(componentID: UUID, src: Int, des: Int) {
        subject.send(.willDropAudioTrack(componentID, src, des))
    }

    func removeAudioTrack(componentID: UUID, trackIndex: Int) {
        subject.send(.willRemoveAudioTrack(componentID, trackIndex))
    }

    func storeDataSource(componentID: UUID, datasource: AudioComponentDataSource) {
        subject.send(.willStoreAudioComponentDataSource(componentID, datasource))
    }
}

final class SinglePageAudioComponentActionDispatcher: AudioComponentActionDispatcher {

    private let subject: PassthroughSubject<SingleAudioPageInput, Never>

    init(subject: PassthroughSubject<SingleAudioPageInput, Never>) {
        self.subject = subject
    }

    func downloadMusics(componentID: UUID, with code: String) {
        subject.send(.willDownloadMusicWithCode(code))
    }

    func playAudioTrack(componentID: UUID, with trackIndex: Int) {
        subject.send(.willPlayAudioTrack(trackIndex))
    }

    func togglePlayingState() {
        subject.send(.willTapPlayPauseButton)
    }

    func playNextAudioTrack() {
        subject.send(.willPlayNextAudioTrack)
    }

    func playPreviousAudioTrack() {
        subject.send(.willPlayPreviousAudioTrack)
    }

    func seekAudioTrack(seek: TimeInterval) {
        subject.send(.willSeekAudioTrack(seek))
    }

    func changeAudioTrackMetadata(editMetadata: AudioTrackMetadata, componentID: UUID, trackIndex: Int) {
        subject.send(.willEditAudioTrackMetadata(editMetadata, trackIndex))
    }

    func presentGallery(_ imageView: UIImageView) {
        subject.send(.willPresentGallery(imageView))
    }

    func changeSortByAudioTracks(componentID: UUID, sortBy: AudioTrackSortBy) {
        subject.send(.willSortAudioTracks(sortBy))
    }

    func dropAudioTrack(componentID: UUID, src: Int, des: Int) {
        subject.send(.willDropAudioTrack(src, des))
    }

    func removeAudioTrack(componentID: UUID, trackIndex: Int) {
        subject.send(.willRemoveAudioTrack(trackIndex))
    }

    func storeDataSource(componentID: UUID, datasource: AudioComponentDataSource) {
        // do notting
    }
}
