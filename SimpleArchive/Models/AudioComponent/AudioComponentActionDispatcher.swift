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
    func changeSortByAudioTracks(componentID: UUID, sortBy: AudioTrackSortBy)
    func moveAudioTrackOrder(componentID: UUID, src: Int, des: Int)
    func removeAudioTrack(componentID: UUID, trackIndex: Int)
    func importAudioFilesFromFileSystem(componentID: UUID, urls: [URL])
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
        subject.send(.willToggleAudioPlayingState)
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
        subject.send(.willApplyAudioMetadataChanges(editMetadata, componentID, trackIndex))
    }

    func changeSortByAudioTracks(componentID: UUID, sortBy: AudioTrackSortBy) {
        subject.send(.willSortAudioTracks(componentID, sortBy))
    }

    func moveAudioTrackOrder(componentID: UUID, src: Int, des: Int) {
        subject.send(.willMoveAudioTrackOrder(componentID, src, des))
    }

    func removeAudioTrack(componentID: UUID, trackIndex: Int) {
        subject.send(.willRemoveAudioTrack(componentID, trackIndex))
    }

    func importAudioFilesFromFileSystem(componentID: UUID, urls: [URL]) {
        subject.send(.willImportAudioFileFromFileSystem(componentID, urls))
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
        subject.send(.willToggleAudioPlayingState)
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
        subject.send(.willApplyAudioMetadataChanges(editMetadata, trackIndex))
    }

    func changeSortByAudioTracks(componentID: UUID, sortBy: AudioTrackSortBy) {
        subject.send(.willSortAudioTracks(sortBy))
    }

    func moveAudioTrackOrder(componentID: UUID, src: Int, des: Int) {
        subject.send(.willMoveAudioTrackOrder(src, des))
    }

    func removeAudioTrack(componentID: UUID, trackIndex: Int) {
        subject.send(.willRemoveAudioTrack(trackIndex))
    }

    func importAudioFilesFromFileSystem(componentID: UUID, urls: [URL]) {
        subject.send(.willImportAudioFilesFromFileSystem(urls))
    }
}
