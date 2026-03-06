import Foundation
import UIKit

class AudioControlBarEventHandler: ComponentViewEventHandlerType {
    private var host: AudioControlBarHost
    private var indexPath: IndexPath
    private var collectionView: UICollectionView

    init(host: AudioControlBarHost, collectionView: UICollectionView, indexPath: IndexPath) {
        self.host = host
        self.indexPath = indexPath
        self.collectionView = collectionView
    }
	
	deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }

    func UIupdateEventHandler(_ event: AudioComponentViewModel.Event) {
        switch event {
            case .didPlayAudioTrack(_, let audioMetadata, _):
                host.activeAudioControlBar(audioMetadata: audioMetadata, dispatcher: nil)

            case .didToggleAudioPlayingState(_, let playbackState):
                host.toggleAudioControlBarPlayBackState(playbackState: playbackState)

            case .didSeekAudioTrack(_, let seek, _):
                host.seekAudioControlBarPlayProgress(seek: seek)

            case .didScrollToActiveAudioTrack(let activeAudioTrackIndex):
                CATransaction.begin()
                CATransaction.setCompletionBlock {
                    if let acv = self.collectionView.cellForItem(at: self.indexPath) as? AudioComponentView {
                        let indexPath = IndexPath(row: activeAudioTrackIndex, section: 0)
                        acv.componentContentView.audioTrackTableView.scrollToRow(
                            at: indexPath, at: .middle, animated: true)
                    }
                }
                collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
                CATransaction.commit()

            default:
                break
        }
    }
}
