import UIKit

final class AudioControlBarHostWindow: UIWindow, AudioControlBarHostType {
    private var audioControlBar: AudioControlBarView
    private var defaultAudioControlBarConstraints: [NSLayoutConstraint] = []
    private var thinAudioControlBarConstraints: [NSLayoutConstraint] = []
    private var isThinLayoutApplied = false

    override init(windowScene: UIWindowScene) {
        audioControlBar = AudioControlBarView()

        super.init(windowScene: windowScene)

        addSubview(audioControlBar)

        defaultAudioControlBarConstraints = [
            audioControlBar.widthAnchor.constraint(equalToConstant: UIConstants.audioControlBarViewWidth),
            audioControlBar.heightAnchor.constraint(equalToConstant: UIConstants.audioControlBarViewHeight),
            audioControlBar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            audioControlBar.centerXAnchor.constraint(equalTo: centerXAnchor),
        ]

        NSLayoutConstraint.activate(defaultAudioControlBarConstraints)

        thinAudioControlBarConstraints = [
            audioControlBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            audioControlBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            audioControlBar.heightAnchor.constraint(equalToConstant: 74),
            audioControlBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
        ]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setAudioControlBarLayoutAsDefault() {
        guard isThinLayoutApplied else { return }
        isThinLayoutApplied = false

        if let navigationController = rootViewController as? UINavigationController,
            let coordinator = navigationController.transitionCoordinator
        {
            coordinator.animate(
                alongsideTransition: { _ in
                    NSLayoutConstraint.deactivate(self.thinAudioControlBarConstraints)
                    NSLayoutConstraint.activate(self.defaultAudioControlBarConstraints)
                    self.audioControlBar.setAudioControlBarLayoutAsDefault()
                    self.layoutIfNeeded()
                },
                completion: { context in
                    if context.isCancelled {
                        self.isThinLayoutApplied = true

                        NSLayoutConstraint.deactivate(self.defaultAudioControlBarConstraints)
                        NSLayoutConstraint.activate(self.thinAudioControlBarConstraints)
                        self.audioControlBar.setAudioControlBarLayoutAsThin()
                        self.layoutIfNeeded()
                    }
                }
            )
        }
    }

    func setAudioControlBarLayoutAsThin() {
        guard !isThinLayoutApplied else { return }
        isThinLayoutApplied = true

        if let navigationController = rootViewController as? UINavigationController,
            let coordinator = navigationController.transitionCoordinator
        {
            coordinator.notifyWhenInteractionChanges { context in
                guard context.isCancelled else { return }

                UIView.animate(
                    withDuration: 0.4,
                    delay: 0,
                    usingSpringWithDamping: 0.45,
                    initialSpringVelocity: 0.7,
                    options: [.curveEaseInOut],
                    animations: {
                        self.isThinLayoutApplied = false

                        NSLayoutConstraint.deactivate(self.thinAudioControlBarConstraints)
                        NSLayoutConstraint.activate(self.defaultAudioControlBarConstraints)
                        self.audioControlBar.setAudioControlBarLayoutAsDefault()
                        self.layoutIfNeeded()
                    }
                )
            }
        }

        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.45,
            initialSpringVelocity: 0.7,
            options: [.curveEaseInOut],
            animations: {
                NSLayoutConstraint.deactivate(self.defaultAudioControlBarConstraints)
                NSLayoutConstraint.activate(self.thinAudioControlBarConstraints)
                self.audioControlBar.setAudioControlBarLayoutAsThin()
                self.layoutIfNeeded()
            }
        )
    }

    func setAudioControlBarEventHandlerForThin() {
        let thinAudioEventHandler = ThinAudioControlBarEventHandler(host: self)
        audioControlBar.dispatcher?.setEventHandler(thinAudioControlBarEventHandler: thinAudioEventHandler)
    }

    func getSingleAudioViewControllerContinuousPlaybackSession(
        audioComponent: AudioComponent,
        pageName: String
    ) -> SingleAudioPageViewController? {

        if audioControlBar.dispatcher?.viewModel?.audioComponentID == audioComponent.id {
            let singleAudioViewController = SingleAudioPageViewController(audioControlBarHost: self)
            let dispatcher = audioControlBar.dispatcher!
            let vm = dispatcher.viewModel!
            let eventHandler = AudioComponentViewEventHandler(
                componentView: singleAudioViewController.audioComponentContentView,
                audioControlBarHost: self)

            if let currentTrackIndex = vm.currentTrackIndex {
                let data = audioComponent.componentContents.tracks[currentTrackIndex].thumbnail
                if let image = UIImage(data: data) {
                    singleAudioViewController.updateBackgroundImage(with: image)
                }
            }

            dispatcher.bindToViewModel(
                viewModel: vm,
                UIEventHandler: eventHandler)

            singleAudioViewController.configure(
                dispatcher: dispatcher,
                audioComponent: audioComponent,
                pageName: pageName)

            return singleAudioViewController
        }
        return nil
    }

    func injectDispatcherContinuousPlaybackSessionInFactory(
        factory: PageComponentCollectionViewCellFactory,
        pageData: MemoPageModel,
        collectionView: UICollectionView
    ) {
        if let dispatcher = audioControlBar.dispatcher, let vm = dispatcher.viewModel {
            let audioComponentID = vm.audioComponentID
            let audioComponentIDList = pageData.getComponents.compactMap { $0 as? AudioComponent }.map { $0.id }

            if Set(audioComponentIDList).contains(audioComponentID) {
                let audioComponentOrder = pageData.getComponents.firstIndex(where: { $0.id == audioComponentID })!
                let indexPath = IndexPath(item: audioComponentOrder, section: 0)

                factory.injectContineiousPlaybackDispatcher(
                    audioComponentId: audioComponentID,
                    dispatcher: dispatcher,
                    vm: vm)

                let controlBarEventHandler = AudioControlBarEventHandler(
                    host: self,
                    collectionView: collectionView,
                    indexPath: indexPath)

                dispatcher.setEventHandler(controlBarEventHandler: controlBarEventHandler)
            }
        }
    }

    func activeAudioControlBar(audioMetadata: AudioTrackMetadata, dispatcher: AudioComponentActionDispatcher?) {
        audioControlBar.alpha = 0
        audioControlBar.isHidden = false
        UIView.animate(withDuration: 0.3) { self.audioControlBar.alpha = 1 }
        audioControlBar.state = .play(metadata: audioMetadata, dispatcher: dispatcher)
    }

    func seekAudioControlBarPlayProgress(seek: TimeInterval) {
        audioControlBar.seek(seek: seek)
    }

    func applyMetadataChangeToAudioControlBar(audioMetadata: AudioTrackMetadata) {
        audioControlBar.applyUpdatedMetadata(with: audioMetadata)
    }

    func toggleAudioControlBarPlayBackState(playbackState: Bool) {
        audioControlBar.state = playbackState ? .resume : .pause
    }

    func stopAudioControlBar() {
        audioControlBar.state = .stop
        audioControlBar.isHidden = true
    }

    func followUpAudioControlBarOnWindow() {
        bringSubviewToFront(audioControlBar)
    }
}

@MainActor protocol AudioControlBarHostType: AnyObject {
    func activeAudioControlBar(audioMetadata: AudioTrackMetadata, dispatcher: AudioComponentActionDispatcher?)
    func toggleAudioControlBarPlayBackState(playbackState: Bool)
    func applyMetadataChangeToAudioControlBar(audioMetadata: AudioTrackMetadata)
    func seekAudioControlBarPlayProgress(seek: TimeInterval)
    func stopAudioControlBar()

    func setAudioControlBarLayoutAsDefault()
    func setAudioControlBarLayoutAsThin()

    func followUpAudioControlBarOnWindow()
    func setAudioControlBarEventHandlerForThin()

    func getSingleAudioViewControllerContinuousPlaybackSession(
        audioComponent: AudioComponent,
        pageName: String
    ) -> SingleAudioPageViewController?

    func injectDispatcherContinuousPlaybackSessionInFactory(
        factory: PageComponentCollectionViewCellFactory,
        pageData: MemoPageModel,
        collectionView: UICollectionView)
}
