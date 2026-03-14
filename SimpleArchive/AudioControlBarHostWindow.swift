import UIKit

enum AudioControlBarLayoutState {
    case `default`
    case thin
    case expended
}

final class AudioControlBarHostWindow: UIWindow, AudioControlBarHostType {
    private let timing = UISpringTimingParameters(mass: 0.5, stiffness: 100, damping: 7, initialVelocity: .zero)
    private var audioControlBar: AudioControlBarView
    private var defaultAudioControlBarConstraints: [NSLayoutConstraint] = []
    private var thinAudioControlBarConstraints: [NSLayoutConstraint] = []
    private let durationFactor = 0.7
    private var expendedAudioControlBarConstraints: [NSLayoutConstraint] = []

    private(set) var audioControlBarLayoutState: AudioControlBarLayoutState = .default

    private var panGesture: UIPanGestureRecognizer!
    private var panStartPointInWindow: CGPoint?
    private var panStartOriginY: CGFloat = 0

    private var thinToExpandedAnimator: UIViewPropertyAnimator?

    private let thinToExpandedRequiredDistance: CGFloat = 100
    private let thinToExpandedInteractiveMaxDistance: CGFloat = 500

    override init(windowScene: UIWindowScene) {
        audioControlBar = AudioControlBarView()

        super.init(windowScene: windowScene)

        setGesture()
        addSubview(audioControlBar)

        defaultAudioControlBarConstraints = [
            audioControlBar.widthAnchor.constraint(equalToConstant: UIConstants.audioControlBarViewWidth),
            audioControlBar.heightAnchor.constraint(equalToConstant: UIConstants.audioControlBarViewHeight),
            audioControlBar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            audioControlBar.centerXAnchor.constraint(equalTo: centerXAnchor),
        ]

        NSLayoutConstraint.activate(defaultAudioControlBarConstraints)

        thinAudioControlBarConstraints = [
            audioControlBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            audioControlBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -80),
            audioControlBar.heightAnchor.constraint(equalToConstant: 70),
            audioControlBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -52.5),
        ]

        let dd = (UIView.screenHeight - 500) * -0.5 + 40

        expendedAudioControlBarConstraints = [
            audioControlBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            audioControlBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            audioControlBar.heightAnchor.constraint(equalToConstant: 500),
            audioControlBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: dd),
        ]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setGesture() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction))
        audioControlBar.addGestureRecognizer(panGesture)
        audioControlBar.audioProgressBar.setGesture(panGesture: panGesture)
    }

    private func updateThinToExpandedInteraction() {
        let timing = UISpringTimingParameters(mass: 0.45, stiffness: 100, damping: 7, initialVelocity: .zero)
        let animator = UIViewPropertyAnimator(duration: 0, timingParameters: timing)

		audioControlBar.alpha = 1
		
        animator.addAnimations {
            NSLayoutConstraint.deactivate(self.thinAudioControlBarConstraints)
            NSLayoutConstraint.activate(self.expendedAudioControlBarConstraints)
            self.audioControlBar.setAudioControlBarLayoutAsExpanded()
            self.layoutIfNeeded()
        }

        animator.isReversed = false

        animator.addCompletion { position in
            if position == .end {
                self.audioControlBarLayoutState = .expended
            } else {
                self.audioControlBarLayoutState = .thin
                NSLayoutConstraint.deactivate(self.expendedAudioControlBarConstraints)
                self.audioControlBar.setAudioControlBarLayoutAsThin()
                NSLayoutConstraint.activate(self.thinAudioControlBarConstraints)
				self.layoutIfNeeded()
            }
            self.thinToExpandedAnimator = nil
            self.panGesture.isEnabled = true
            self.audioControlBar.audioProgressBar.isProgressUpdateEnable = true
            self.audioControlBar.unblockTouch()
        }

        thinToExpandedAnimator = animator
        animator.startAnimation()
        animator.pauseAnimation()
    }

    private func updateExpandedToThinInteraction() {
        let timing = UISpringTimingParameters(mass: 0.3, stiffness: 100, damping: 7, initialVelocity: .zero)
        let animator = UIViewPropertyAnimator(duration: 0.6, timingParameters: timing)

        animator.addAnimations {
            NSLayoutConstraint.deactivate(self.expendedAudioControlBarConstraints)
            self.audioControlBar.setAudioControlBarLayoutAsThin()
            NSLayoutConstraint.activate(self.thinAudioControlBarConstraints)
            self.layoutIfNeeded()
        }

        animator.isReversed = false

        animator.addCompletion { position in
            if position == .end {
                myLog("thin 성공")
                self.audioControlBarLayoutState = .thin
            } else {
                myLog("thin 취소됨")
                self.audioControlBarLayoutState = .expended
                NSLayoutConstraint.deactivate(self.thinAudioControlBarConstraints)
                NSLayoutConstraint.activate(self.expendedAudioControlBarConstraints)
                self.audioControlBar.setAudioControlBarLayoutAsExpanded()
                self.layoutIfNeeded()
            }
            self.panGesture.isEnabled = true
            self.audioControlBar.audioProgressBar.isProgressUpdateEnable = true
            self.audioControlBar.unblockTouch()
            self.thinToExpandedAnimator = nil
        }

        thinToExpandedAnimator = animator
        animator.startAnimation()
        animator.pauseAnimation()
    }

    private func dismissAudioControlBar() {
        audioControlBar.audioProgressBar.pauseProgress()

        UIView.animate(withDuration: 0.3) {
            self.audioControlBar.alpha = 0
            self.audioControlBar.frame.origin.y += 100
        } completion: { _ in
            self.audioControlBar.alpha = 1
            self.audioControlBar.isHidden = true
            self.audioControlBarLayoutState = .default

            NSLayoutConstraint.deactivate(self.expendedAudioControlBarConstraints)
            NSLayoutConstraint.deactivate(self.thinAudioControlBarConstraints)
            NSLayoutConstraint.activate(self.defaultAudioControlBarConstraints)
            self.audioControlBar.setAudioControlBarLayoutAsDefault()

            self.audioControlBar.dispatcher?.dissmissAudioControlBar()

            self.panGesture.isEnabled = true
            self.audioControlBar.audioProgressBar.isProgressUpdateEnable = true
            self.audioControlBar.unblockTouch()
            self.thinToExpandedAnimator = nil

            self.layoutIfNeeded()
        }
    }

    private func gestureChanges(deltaY: CGFloat) {
        let isDraggingBotton = deltaY > 0
        let deltaAbs = abs(deltaY)

        switch audioControlBarLayoutState {
            case .default:
                if isDraggingBotton {
                    audioControlBar.frame.origin.y = panStartOriginY + deltaAbs
                    audioControlBar.alpha = 1 - deltaAbs * 0.004
                } else {
                    audioControlBar.frame.origin.y = panStartOriginY
                    audioControlBar.alpha = 1
                }

            case .thin:
                if isDraggingBotton {
                    thinToExpandedAnimator?.fractionComplete = 0
                    thinToExpandedAnimator?.isReversed = true
                    thinToExpandedAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 0)
                    thinToExpandedAnimator = nil

                    audioControlBar.frame.origin.y = panStartOriginY + deltaAbs
                    audioControlBar.alpha = 1 - deltaAbs * 0.008
                } else {
                    if thinToExpandedAnimator == nil {
                        updateThinToExpandedInteraction()
                    } else {
                        let progress = min(max(deltaAbs / thinToExpandedInteractiveMaxDistance, 0), 1)
                        thinToExpandedAnimator?.fractionComplete = progress
                    }
                }

            case .expended:
                if isDraggingBotton {
                    if thinToExpandedAnimator == nil {
                        updateExpandedToThinInteraction()
                    } else {
                        let progress = min(max(deltaAbs / thinToExpandedInteractiveMaxDistance, 0), 1)
                        thinToExpandedAnimator?.fractionComplete = progress
                    }
                } else {
                    thinToExpandedAnimator?.fractionComplete = 0
                }
        }
    }

    private func gestureComplete(deltaY: CGFloat) {
        let isDraggingBotton = deltaY > 0
        let deltaAbs = abs(deltaY)

        switch audioControlBarLayoutState {
            case .default:
                if isDraggingBotton {
                    if deltaAbs >= 100 {
                        dismissAudioControlBar()
                    } else {
                        transitionAnimationWith {
                            self.audioControlBar.alpha = 1
                            self.audioControlBar.frame.origin.y = self.panStartOriginY
                        }
                        audioControlBar.audioProgressBar.isProgressUpdateEnable = true
                        panGesture.isEnabled = true
                        audioControlBar.unblockTouch()
                    }
                } else {
                    transitionAnimationWith {
                        self.audioControlBar.alpha = 1
                        self.audioControlBar.frame.origin.y = self.panStartOriginY
                    }
                    audioControlBar.audioProgressBar.isProgressUpdateEnable = true
                    panGesture.isEnabled = true
                    audioControlBar.unblockTouch()
                }

            case .thin:
                if isDraggingBotton {
                    if deltaAbs >= 50 {
                        dismissAudioControlBar()
                    } else {
                        if let thinToExpandedAnimator {
                            self.audioControlBar.alpha = 1
                            self.audioControlBar.frame.origin.y = self.panStartOriginY
                            thinToExpandedAnimator.isReversed = true
                            thinToExpandedAnimator
                                .continueAnimation(withTimingParameters: nil, durationFactor: durationFactor)
                        } else {
                            audioControlBarLayoutState = .thin

                            audioControlBar.audioProgressBar.isProgressUpdateEnable = false
                            panGesture.isEnabled = false
                            audioControlBar.blockTouch()

                            transitionAnimationWith(
                                {
                                    self.audioControlBar.alpha = 1
                                    self.audioControlBar.frame.origin.y = self.panStartOriginY
                                },
                                comp: {
                                    self.audioControlBar.audioProgressBar.isProgressUpdateEnable = true
                                    self.panGesture.isEnabled = true
                                    self.audioControlBar.unblockTouch()
                                })
                        }
                    }
                } else {
                    if deltaAbs >= 100 {
                        audioControlBarLayoutState = .expended
                        thinToExpandedAnimator?
                            .continueAnimation(withTimingParameters: nil, durationFactor: durationFactor)
                    } else {
                        audioControlBarLayoutState = .thin
                        thinToExpandedAnimator?.isReversed = true
                        thinToExpandedAnimator?
                            .continueAnimation(withTimingParameters: nil, durationFactor: durationFactor)
                    }
                }

            case .expended:
                if isDraggingBotton {
                    if deltaAbs >= 100 {
                        audioControlBarLayoutState = .thin
                        thinToExpandedAnimator?
                            .continueAnimation(withTimingParameters: nil, durationFactor: 0.7)
                    } else {
                        audioControlBarLayoutState = .expended
                        thinToExpandedAnimator?.isReversed = true
                        thinToExpandedAnimator?
                            .continueAnimation(withTimingParameters: nil, durationFactor: 1.0)
                    }
                } else {
                    myLog("expended에서 위로 들어올림")

                    audioControlBarLayoutState = .expended

                    thinToExpandedAnimator?.isReversed = true
                    thinToExpandedAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 1.0)

                    thinToExpandedAnimator = nil
                }
        }
    }

    @objc func panGestureAction(_ sender: UIPanGestureRecognizer) {
        let currentPoint = sender.location(in: self)

        switch sender.state {
            case .began:
                audioControlBar.blockTouch()
                audioControlBar.audioProgressBar.isProgressUpdateEnable = false

                panStartPointInWindow = currentPoint
                panStartOriginY = audioControlBar.frame.origin.y

            case .changed:
                guard let start = panStartPointInWindow else { return }
                let deltaY = currentPoint.y - start.y
                gestureChanges(deltaY: deltaY)

            case .ended, .cancelled, .failed:
                panGesture.isEnabled = false
                guard let start = panStartPointInWindow else { return }
                let deltaY = currentPoint.y - start.y
                gestureComplete(deltaY: deltaY)

            default:
                break
        }
    }

    func setAudioControlBarLayoutAsDefault() {
        switch audioControlBarLayoutState {
            case .default:
                break

            case .thin:
                if let navigationController = rootViewController as? UINavigationController,
                    let coordinator = navigationController.transitionCoordinator
                {
                    coordinator.animate(
                        alongsideTransition: { _ in
                            self.audioControlBarLayoutState = .default

                            NSLayoutConstraint.deactivate(self.thinAudioControlBarConstraints)
                            NSLayoutConstraint.activate(self.defaultAudioControlBarConstraints)
                            self.audioControlBar.setAudioControlBarLayoutAsDefault()
                            self.layoutIfNeeded()
                        },
                        completion: { context in
                            if context.isCancelled {
                                self.audioControlBarLayoutState = .thin

                                NSLayoutConstraint.deactivate(self.defaultAudioControlBarConstraints)
                                NSLayoutConstraint.activate(self.thinAudioControlBarConstraints)
                                self.audioControlBar.setAudioControlBarLayoutAsThin()
                                self.layoutIfNeeded()
                            }
                        }
                    )
                }

            case .expended:
                if let navigationController = rootViewController as? UINavigationController,
                    let coordinator = navigationController.transitionCoordinator
                {
                    coordinator.animate(
                        alongsideTransition: { _ in
                            self.audioControlBarLayoutState = .default

                            NSLayoutConstraint.deactivate(self.expendedAudioControlBarConstraints)
                            NSLayoutConstraint.activate(self.defaultAudioControlBarConstraints)
                            self.audioControlBar.setAudioControlBarLayoutAsDefault()
                            self.layoutIfNeeded()
                        },
                        completion: { context in
                            if context.isCancelled {
                                self.audioControlBarLayoutState = .expended

                                NSLayoutConstraint.deactivate(self.defaultAudioControlBarConstraints)
                                NSLayoutConstraint.activate(self.expendedAudioControlBarConstraints)
                                self.audioControlBar.setAudioControlBarLayoutAsExpanded()
                                self.layoutIfNeeded()
                            }
                        }
                    )
                }
        }
    }

    func setAudioControlBarLayoutAsThin() {
        switch audioControlBarLayoutState {
            case .default:
                if let navigationController = rootViewController as? UINavigationController,
                    let coordinator = navigationController.transitionCoordinator
                {
                    coordinator.notifyWhenInteractionChanges { context in
                        guard context.isCancelled else { return }

                        self.transitionAnimationWith {
                            self.audioControlBarLayoutState = .default

                            NSLayoutConstraint.deactivate(self.thinAudioControlBarConstraints)
                            NSLayoutConstraint.activate(self.defaultAudioControlBarConstraints)
                            self.audioControlBar.setAudioControlBarLayoutAsDefault()
                            self.layoutIfNeeded()
                        }
                    }
                }

                transitionAnimationWith {
                    self.audioControlBarLayoutState = .thin

                    NSLayoutConstraint.deactivate(self.defaultAudioControlBarConstraints)
                    NSLayoutConstraint.activate(self.thinAudioControlBarConstraints)
                    self.audioControlBar.setAudioControlBarLayoutAsThin()
                    self.layoutIfNeeded()
                }

            case .thin:
                break

            case .expended:
                self.audioControlBarLayoutState = .thin

                NSLayoutConstraint.deactivate(self.expendedAudioControlBarConstraints)
                NSLayoutConstraint.activate(self.thinAudioControlBarConstraints)
                self.audioControlBar.setAudioControlBarLayoutAsThin()
                self.layoutIfNeeded()

        }
    }

    func setAudioControlBarLayoutAsExpended() {
        switch audioControlBarLayoutState {
            case .default:
                break

            case .thin:
                transitionAnimationWith {
                    self.audioControlBarLayoutState = .expended

                    NSLayoutConstraint.deactivate(self.thinAudioControlBarConstraints)
                    NSLayoutConstraint.activate(self.expendedAudioControlBarConstraints)
                    self.audioControlBar.setAudioControlBarLayoutAsExpanded()
                    self.layoutIfNeeded()
                }

            case .expended:
                break
        }
    }

    private func transitionAnimationWith(_ with: @escaping () -> Void, comp: (() -> Void)? = nil) {
        UIView.animate(
            withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.45,
            initialSpringVelocity: 0.7, options: [.curveEaseInOut],
            animations: { with() }, completion: { _ in comp?() })
    }

    func setAudioControlBarEventHandlerForThin() {
        let thinAudioEventHandler = ThinAudioControlBarEventHandler(host: self)
        audioControlBar.dispatcher?.setEventHandler(thinAudioControlBarEventHandler: thinAudioEventHandler)
        audioControlBar.dispatcher?.changeAudioControlBarStateAsThin()
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

    func setListiViewData(data: AudioComponent) -> ExpendedAudioControlBarTrackListView {
        audioControlBar.setAudioTrackListView(data: data)
    }
}

@MainActor protocol AudioControlBarHostType: AnyObject {
    func activeAudioControlBar(audioMetadata: AudioTrackMetadata, dispatcher: AudioComponentActionDispatcher?)
    func toggleAudioControlBarPlayBackState(playbackState: Bool)
    func applyMetadataChangeToAudioControlBar(audioMetadata: AudioTrackMetadata)
    func seekAudioControlBarPlayProgress(seek: TimeInterval)
    func stopAudioControlBar()
    func setListiViewData(data: AudioComponent) -> ExpendedAudioControlBarTrackListView

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
