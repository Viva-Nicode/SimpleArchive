import Combine
import UIKit

final class AudioComponentView: PageComponentView<AudioComponentContentView, AudioComponent> {
    private static var audioTableViewScrollOffsetCache: [UUID: CGFloat] = [:]
    static let reuseAudioComponentIdentifier: String = "reuseAudioComponentIdentifier"
    private var audioComponentDataSource: AudioComponentDataSource?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupUI() {
        componentContentView = AudioComponentContentView()
        componentContentView.translatesAutoresizingMaskIntoConstraints = false
        componentContentView.layer.cornerRadius = 10
        componentContentView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        componentContentView.backgroundColor = .systemGray6

        super.setupUI()

        toolBarView.backgroundColor = UIColor(named: "AudioComponentToolbarColor")
    }

    override func prepareForReuse() {
        if let componentID {
            Self.audioTableViewScrollOffsetCache[componentID] =
                componentContentView.audioTrackTableView.contentOffset.y
        }
        super.prepareForReuse()
    }

    override func freedReferences() {
        super.freedReferences()
    }

    func configureAudioComponentForMemoPageView(
        component: AudioComponent,
        pageActionDispatcher: PassthroughSubject<MemoPageViewInput, Never>,
        audioActionDispatcher: AudioComponentActionDispatcher
    ) {
        super
            .configure(
                componentID: component.id,
                componentTitle: component.title,
                componentCreateAt: component.creationDate,
                pageActionDispatcher: pageActionDispatcher)

        audioComponentDataSource = AudioComponentDataSource(audioPageComponent: component)
        componentContentView.audioTrackTableView.dataSource = audioComponentDataSource

        componentContentView.configure(
            trackCount: component.componentContents.tracks.count,
            isFolding: component.isMinimumHeight,
            sortBy: component.componentContents.sortBy,
            dispatcher: audioActionDispatcher)

        componentContentView.audioTrackTableView.reloadData()
        adjustAudioTableViewScrollOffset(componentID: component.id)
    }

    private func adjustAudioTableViewScrollOffset(componentID: UUID) {
        let audioTrackTableView = componentContentView.audioTrackTableView
        audioTrackTableView.layoutIfNeeded()
        let topY = -audioTrackTableView.adjustedContentInset.top
        let restoredY = Self.audioTableViewScrollOffsetCache[componentID] ?? topY
        audioTrackTableView.setContentOffset(CGPoint(x: 0, y: restoredY), animated: false)
    }

    override func presentFullScreenPageComponentView() {
        if let memoPageViewController = parentViewController as? MemoPageViewController {
            memoPageViewController.fullscreenTargetComponentContentsViewFrame = componentContentView.convert(
                componentContentView.bounds, to: memoPageViewController.view.window!)

            let fullscreenComponentViewController = FullScreenAudioComponentViewController(
                title: titleLabel.text!,
                createdDate: createdAt,
                audioComponentContentView: componentContentView)

            fullscreenComponentViewController.modalPresentationStyle = .fullScreen
            fullscreenComponentViewController.transitioningDelegate = memoPageViewController

            memoPageViewController.present(fullscreenComponentViewController, animated: true)
        }
    }

    override func setMinimizeState(_ isMinimize: Bool) {
        componentContentView.minimizeContentView(isMinimize)
    }
}
