import UIKit

final class AudioControlBarHostWindow: UIWindow, AudioControlBarHostType {
    private(set) var audioControlBar: AudioControlBarView
    private(set) var audioControlBarLayoutState: AudioControlBarLayoutState = .default

    private var defaultAudioControlBarConstraints: [NSLayoutConstraint] = []
    private var thinAudioControlBarConstraints: [NSLayoutConstraint] = []
    private var expendedAudioControlBarConstraints: [NSLayoutConstraint] = []
    private var dismissAudioControlBarConstraints: [NSLayoutConstraint] = []

    private var panGesture: UIPanGestureRecognizer!
    private var panStartPointInWindow: CGPoint?
    private var panStartOriginY: CGFloat = 0
    private var isSwipingFast = false

    private var thinExpandedTransitionAnimator: UIViewPropertyAnimator?
    private var thinToDismissAnimator: UIViewPropertyAnimator?

    private var thinBottonConstant: CGFloat = -52.5
	private let expendedBottonConstant:CGFloat = -(60 + 55 + 12)
    private let expendedContentsWidth = UIView.screenWidth - 50
    private let expendedContentHeight: CGFloat = 420

    private let interactionBlockWindow: UIView = {
        let blockWindow = UIView()
        blockWindow.isUserInteractionEnabled = true
        blockWindow.backgroundColor = .clear
        blockWindow.translatesAutoresizingMaskIntoConstraints = false
        return blockWindow
    }()

    private var invisibleControlBarVC: UIViewController?
    private let invisibleControlBarViewTypes = [
        UIDocumentPickerViewController.self,
        CreateNewComponentView.self,
        FullScreenAudioComponentViewController.self,
        FullScreenTextEditorComponentViewController.self,
        FullScreenTableComponentViewController.self,
    ]

    var audioControlBarState: AudioControlBarViewState { audioControlBar.state }

    override init(windowScene: UIWindowScene) {
        audioControlBar = AudioControlBarView()

        super.init(windowScene: windowScene)

        panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction))
        audioControlBar.addGestureRecognizer(panGesture)
        audioControlBar.audioProgressBar.setGesture(panGesture: panGesture)

        addSubview(audioControlBar)
        addSubview(interactionBlockWindow)
        sendSubviewToBack(interactionBlockWindow)

        NSLayoutConstraint.activate([
            interactionBlockWindow.topAnchor.constraint(equalTo: topAnchor),
            interactionBlockWindow.leadingAnchor.constraint(equalTo: leadingAnchor),
            interactionBlockWindow.trailingAnchor.constraint(equalTo: trailingAnchor),
            interactionBlockWindow.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        defaultAudioControlBarConstraints = [
            audioControlBar.widthAnchor.constraint(equalToConstant: UIConstants.audioControlBarViewWidth),
            audioControlBar.heightAnchor.constraint(equalToConstant: UIConstants.audioControlBarViewHeight),
            audioControlBar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            audioControlBar.centerXAnchor.constraint(equalTo: centerXAnchor),
        ]

        NSLayoutConstraint.activate(defaultAudioControlBarConstraints)

        thinAudioControlBarConstraints = [
            audioControlBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            audioControlBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -73),
            audioControlBar.heightAnchor.constraint(equalToConstant: 70),
            audioControlBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: thinBottonConstant),
        ]

        dismissAudioControlBarConstraints = [
            audioControlBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            audioControlBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -73),
            audioControlBar.heightAnchor.constraint(equalToConstant: 70),
            audioControlBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 50),
        ]

        expendedAudioControlBarConstraints = [
            audioControlBar.centerXAnchor.constraint(equalTo: centerXAnchor),
            audioControlBar.widthAnchor.constraint(equalToConstant: expendedContentsWidth),
            audioControlBar.heightAnchor.constraint(equalToConstant: expendedContentHeight),
            audioControlBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: expendedBottonConstant),
        ]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeKey() {
        super.becomeKey()
        bringSubviewToFront(audioControlBar)
    }

    // layoutSubviews와 didAddSubview로 audioControlBar가 숨겨져야하는 뷰가 present될때를 감지하여 가시성을 전환한다
    override func layoutSubviews() {
        super.layoutSubviews()

        if invisibleControlBarVC != nil && invisibleControlBarVC?.view.window == nil {
            audioControlBar.isHidden = false
            UIView.animate(
                withDuration: 0.3,
                animations: { self.audioControlBar.alpha = 1 },
                completion: { _ in self.invisibleControlBarVC = nil }
            )
        }
    }

    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        bringSubviewToFront(audioControlBar)

        if let rootVC = rootViewController as? UINavigationController,
            let topVC = rootVC.topViewController,
            let invisibleControlBarVC = topVC.presentedViewController,
            invisibleControlBarViewTypes.contains(where: { invisibleControlBarVC.isKind(of: $0) }),
            ![.initial, .stop].contains(audioControlBarState)
        {
            if self.invisibleControlBarVC != nil { return }
            self.invisibleControlBarVC = invisibleControlBarVC

            UIView.animate(
                withDuration: 0.3,
                animations: { self.audioControlBar.alpha = 0 },
                completion: { _ in self.audioControlBar.isHidden = true })
        }
    }

    // 홈화면에서 이벤트 발생 시 플러스버튼을 접는다
    override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event)

        guard
            let rootVC = rootViewController as? UINavigationController,
            let topVC = rootVC.topViewController,
            let homeVC = topVC as? MemoHomeViewController,
            homeVC.isActiveFileCreatePlusButton,
            let touchPoint = event.allTouches?.first?.location(in: self),
            let eventGenerateView = hitTest(touchPoint, with: event),
            eventGenerateView.accessibilityIdentifier != "MemoHomeVC.fileCreatePlusButton"
        else { return }

        homeVC.toggleCreateNewItemButtonVisibility()
    }

    func setAudioControlBarLayoutAsDefault() {
        if let navigationController = rootViewController as? UINavigationController,
            let coordinator = navigationController.transitionCoordinator
        {
            coordinator.animate { _ in self.updateLayoutConstraintToDefault() }
        }
    }

    func setAudioControlBarLayoutAsThin() {
        switch audioControlBarLayoutState {
            case .default:
                if let navigationController = rootViewController as? UINavigationController,
                    let coordinator = navigationController.transitionCoordinator
                {
                    coordinator.animate(
                        alongsideTransition: { _ in self.updateLayoutConstraintToThin() },
                        completion: {
                            if $0.isCancelled { self.updateLayoutConstraintToDefault() }
                        }
                    )
                }

            case .expended:
                audioControlBar.blockTouch()
                audioControlBar.audioProgressBar.isProgressUpdateEnable = false
                toggleBlockedInteractionOnWindow(true)
                panGesture.isEnabled = false

                if thinExpandedTransitionAnimator != nil {
                    thinExpandedTransitionAnimator?.isReversed = true
                    thinExpandedTransitionAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 1.5)
                } else {
                    setExpandedToThinAnimation()
                    thinExpandedTransitionAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 0)
                }

            default:
                break
        }
    }

    func setAudioControlBarEventHandlerForThin() {
        let continuousPlaybackControlBarEventHandler = ContinuousPlaybackControlBarEventHandler(
            audioControlBarHost: self,
            expendedAudioList: audioControlBar.audioTrackListView)
        audioControlBar.dispatcher?
            .setEventHandler(
                continuousPlaybackControlBarEventHandler: continuousPlaybackControlBarEventHandler)
        audioControlBar.dispatcher?.changeAudioControlBarStateAsThin()
    }

    func getSingleAudioViewControllerContinuousPlaybackSession(
        audioComponent: AudioComponent, pageName: String
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
        if audioControlBar.isHidden {
            audioControlBar.alpha = 0
            audioControlBar.isHidden = false
            UIView.animate(withDuration: 0.3) { self.audioControlBar.alpha = 1 }
        }
        enableAudioControlBarUserInteracting()
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

    private func setThinToExpandedAnimation() {
        let timing = UISpringTimingParameters(mass: 0.45, stiffness: 100, damping: 7, initialVelocity: .zero)
        let animator = UIViewPropertyAnimator(duration: 0, timingParameters: timing)

        animator.addAnimations {
            NSLayoutConstraint.deactivate(self.dismissAudioControlBarConstraints)
            NSLayoutConstraint.deactivate(self.thinAudioControlBarConstraints)
            NSLayoutConstraint.activate(self.expendedAudioControlBarConstraints)
            self.audioControlBar.setAudioControlBarLayoutAsExpanded()
            self.layoutIfNeeded()
        }

        animator.addCompletion { position in
            switch position {
                case .end:
                    self.audioControlBarLayoutState = .expended
                    self.enableAudioControlBarUserInteracting()

                case .start:
                    self.updateLayoutConstraintToThin()
                    self.enableAudioControlBarUserInteracting()

                case .current:
                    self.updateLayoutConstraintToThin()
                    self.setThinToDismissAnimation()

                @unknown default:
                    break
            }
            self.thinExpandedTransitionAnimator = nil
        }

        thinExpandedTransitionAnimator = animator

        animator.startAnimation()
        animator.pauseAnimation()
    }

    private func setExpandedToThinAnimation() {
        let timing = UISpringTimingParameters(mass: 0.3, stiffness: 100, damping: 7, initialVelocity: .zero)
        let animator = UIViewPropertyAnimator(duration: 0, timingParameters: timing)

        animator.addAnimations {
            NSLayoutConstraint.deactivate(self.expendedAudioControlBarConstraints)
            self.audioControlBar.setAudioControlBarLayoutAsThin()
            NSLayoutConstraint.activate(self.thinAudioControlBarConstraints)
            self.layoutIfNeeded()
        }

        animator.addCompletion { position in
            if position == .end {
                self.audioControlBarLayoutState = .thin
            } else {
                self.updateLayoutConstraintToExpended()
            }

            self.enableAudioControlBarUserInteracting()
            self.thinExpandedTransitionAnimator = nil
        }

        thinExpandedTransitionAnimator = animator

        animator.startAnimation()
        animator.pauseAnimation()
    }

    private func enableAudioControlBarUserInteracting() {
        panGesture.isEnabled = true
        audioControlBar.audioProgressBar.isProgressUpdateEnable = true
        audioControlBar.unblockTouch()
        toggleBlockedInteractionOnWindow(false)
    }

    private func setThinToDismissAnimation() {
        let timing = UISpringTimingParameters(mass: 0.3, stiffness: 100, damping: 7, initialVelocity: .zero)
        thinToDismissAnimator = UIViewPropertyAnimator(duration: 0, timingParameters: timing)

        thinToDismissAnimator?
            .addAnimations {
                self.audioControlBar.alpha = 0
                NSLayoutConstraint.deactivate(self.defaultAudioControlBarConstraints)
                NSLayoutConstraint.deactivate(self.thinAudioControlBarConstraints)
                NSLayoutConstraint.activate(self.dismissAudioControlBarConstraints)
                self.layoutIfNeeded()
            }

        thinToDismissAnimator?
            .addCompletion { position in
                switch position {
                    case .end:
                        self.audioControlBar.audioProgressBar.pauseProgress()
                        self.audioControlBar.dispatcher?.dissmissAudioControlBar()
                        self.enableAudioControlBarUserInteracting()
                        self.updateLayoutConstraintToDefault()

                    case .start:
                        self.updateLayoutConstraintToThin()
                        self.enableAudioControlBarUserInteracting()

                    case .current:
                        self.audioControlBar.alpha = 1
                        self.updateLayoutConstraintToThin()

                    @unknown default:
                        break
                }

                self.thinToDismissAnimator = nil
            }

        self.thinToDismissAnimator?.startAnimation()
        self.thinToDismissAnimator?.pauseAnimation()
    }

    private func dismissAudioControlBar() {
        audioControlBar.audioProgressBar.pauseProgress()
        UIView.animate(withDuration: 0.3) {
            self.audioControlBar.alpha = 0
            self.audioControlBar.frame.origin.y += 200
        } completion: { _ in
            self.audioControlBar.isHidden = true
            self.updateLayoutConstraintToDefault()
            self.audioControlBar.dispatcher?.dissmissAudioControlBar()

            self.thinExpandedTransitionAnimator = nil
            self.thinToDismissAnimator = nil

            self.layoutIfNeeded()
        }
    }

    private func updateLayoutConstraintToDefault() {
        audioControlBarLayoutState = .default

        NSLayoutConstraint.deactivate(dismissAudioControlBarConstraints)
        NSLayoutConstraint.deactivate(expendedAudioControlBarConstraints)
        NSLayoutConstraint.deactivate(thinAudioControlBarConstraints)
        NSLayoutConstraint.activate(defaultAudioControlBarConstraints)
        audioControlBar.setAudioControlBarLayoutAsDefault()
        layoutIfNeeded()
    }

    private func updateLayoutConstraintToThin() {
        audioControlBarLayoutState = .thin

        NSLayoutConstraint.deactivate(dismissAudioControlBarConstraints)
        NSLayoutConstraint.deactivate(expendedAudioControlBarConstraints)
        NSLayoutConstraint.deactivate(defaultAudioControlBarConstraints)
        audioControlBar.setAudioControlBarLayoutAsThin()
        NSLayoutConstraint.activate(thinAudioControlBarConstraints)
        layoutIfNeeded()
    }

    private func updateLayoutConstraintToExpended() {
        audioControlBarLayoutState = .expended

        NSLayoutConstraint.deactivate(thinAudioControlBarConstraints)
        NSLayoutConstraint.deactivate(defaultAudioControlBarConstraints)
        NSLayoutConstraint.activate(expendedAudioControlBarConstraints)
        audioControlBar.setAudioControlBarLayoutAsExpanded()
        layoutIfNeeded()
    }

    private func toggleBlockedInteractionOnWindow(_ isBlock: Bool) {
        if isBlock {
            bringSubviewToFront(interactionBlockWindow)
            bringSubviewToFront(audioControlBar)
        } else {
            sendSubviewToBack(interactionBlockWindow)
        }
    }

    @objc func panGestureAction(_ sender: UIPanGestureRecognizer) {
        let currentPoint = sender.location(in: self)
        let velocity = sender.velocity(in: self)

        isSwipingFast = velocity.y.magnitude >= 300

        switch sender.state {
            case .began:
                audioControlBar.blockTouch()
                audioControlBar.audioProgressBar.isProgressUpdateEnable = false
                toggleBlockedInteractionOnWindow(true)

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

    private func gestureChanges(deltaY: CGFloat) {
        let isDraggingBotton = deltaY > 0
        let deltaAbs = abs(deltaY)

        switch audioControlBarLayoutState {
            case .default:
                if isDraggingBotton {
                    audioControlBar.frame.origin.y = panStartOriginY + deltaAbs
                    audioControlBar.alpha = 1 - deltaAbs * 0.004
                } else {
                    audioControlBar.frame.origin.y = max(panStartOriginY - deltaAbs, panStartOriginY - 150)
                    audioControlBar.alpha = 1
                }

            case .thin:
                if isDraggingBotton {
                    thinExpandedTransitionAnimator?.stopAnimation(false)
                    thinExpandedTransitionAnimator?.finishAnimation(at: .current)
                    thinExpandedTransitionAnimator = nil

                    if thinToDismissAnimator == nil { setThinToDismissAnimation() }

                    let progress = min(max(deltaAbs / 100, 0), 1)
                    thinToDismissAnimator?.fractionComplete = progress
                } else {
                    thinToDismissAnimator?.stopAnimation(false)
                    thinToDismissAnimator?.finishAnimation(at: .current)

                    if thinExpandedTransitionAnimator == nil {
                        setThinToExpandedAnimation()
                    } else {
                        let progress = min(max(deltaAbs / expendedContentHeight, 0), 1)
                        thinExpandedTransitionAnimator?.fractionComplete = progress
                    }
                }

            case .expended:
                if isDraggingBotton {
                    if thinExpandedTransitionAnimator == nil {
                        setExpandedToThinAnimation()
                    } else {
                        let progress = min(max(deltaAbs / expendedContentHeight, 0), 1)
                        thinExpandedTransitionAnimator?.fractionComplete = progress
                    }
                } else {
                    thinExpandedTransitionAnimator?.fractionComplete = 0
                }
        }
    }

    private func gestureComplete(deltaY: CGFloat) {
        let isDraggingBotton = deltaY > 0
        let deltaAbs = abs(deltaY)

        switch audioControlBarLayoutState {
            case .default:
                if isDraggingBotton {
                    if deltaAbs >= 100 || isSwipingFast {
                        dismissAudioControlBar()
                    } else {
                        UIView.springAnimation {
                            self.audioControlBar.alpha = 1
                            self.audioControlBar.frame.origin.y = self.panStartOriginY
                        } comp: {
                            self.enableAudioControlBarUserInteracting()
                        }
                    }
                } else {
                    UIView.springAnimation {
                        self.audioControlBar.alpha = 1
                        self.audioControlBar.frame.origin.y = self.panStartOriginY
                    } comp: {
                        self.enableAudioControlBarUserInteracting()
                    }
                }

            case .thin:
                if isDraggingBotton {
                    guard let thinToDismissAnimator else {
                        audioControlBarLayoutState = .thin
                        enableAudioControlBarUserInteracting()
                        return
                    }
                    if deltaAbs >= 70 || isSwipingFast {
                        audioControlBarLayoutState = .default
                        thinToDismissAnimator.continueAnimation(withTimingParameters: nil, durationFactor: 1)
                    } else {
                        audioControlBarLayoutState = .thin
                        thinToDismissAnimator.isReversed = true
                        let timing = UISpringTimingParameters(
                            mass: 0.3, stiffness: 5, damping: 1, initialVelocity: .init(dx: 0, dy: 0.5))
                        thinToDismissAnimator.continueAnimation(withTimingParameters: timing, durationFactor: 1)
                    }
                } else {
                    guard let thinExpandedTransitionAnimator else {
                        audioControlBarLayoutState = .thin
                        enableAudioControlBarUserInteracting()
                        return
                    }

                    if deltaAbs >= 150 || isSwipingFast {
                        audioControlBarLayoutState = .expended
                        thinExpandedTransitionAnimator
                            .continueAnimation(withTimingParameters: nil, durationFactor: 0.7)
                    } else {
                        audioControlBarLayoutState = .thin

                        thinExpandedTransitionAnimator.isReversed = true
                        thinExpandedTransitionAnimator
                            .continueAnimation(withTimingParameters: nil, durationFactor: 0.7)
                    }
                }

            case .expended:
                guard let thinExpandedTransitionAnimator else {
                    audioControlBarLayoutState = .expended
                    enableAudioControlBarUserInteracting()
                    return
                }
                if isDraggingBotton {
                    if deltaAbs >= 150 || isSwipingFast {
                        audioControlBarLayoutState = .thin
                        thinExpandedTransitionAnimator
                            .continueAnimation(withTimingParameters: nil, durationFactor: 0.7)
                    } else {
                        audioControlBarLayoutState = .expended
                        thinExpandedTransitionAnimator.isReversed = true
                        thinExpandedTransitionAnimator
                            .continueAnimation(withTimingParameters: nil, durationFactor: 1.0)
                    }
                } else {
                    audioControlBarLayoutState = .expended

                    thinExpandedTransitionAnimator.isReversed = true
                    thinExpandedTransitionAnimator
                        .continueAnimation(withTimingParameters: nil, durationFactor: 1.0)
                }
        }
    }
}

@MainActor protocol AudioControlBarHostType: AnyObject {
    var audioControlBarLayoutState: AudioControlBarLayoutState { get }

    func activeAudioControlBar(audioMetadata: AudioTrackMetadata, dispatcher: AudioComponentActionDispatcher?)
    func toggleAudioControlBarPlayBackState(playbackState: Bool)
    func applyMetadataChangeToAudioControlBar(audioMetadata: AudioTrackMetadata)
    func seekAudioControlBarPlayProgress(seek: TimeInterval)
    func stopAudioControlBar()

    func setAudioControlBarLayoutAsDefault()
    func setAudioControlBarLayoutAsThin()
    func setAudioControlBarEventHandlerForThin()

    func getSingleAudioViewControllerContinuousPlaybackSession(audioComponent: AudioComponent, pageName: String)
        -> SingleAudioPageViewController?
    func injectDispatcherContinuousPlaybackSessionInFactory(
        factory: PageComponentCollectionViewCellFactory,
        pageData: MemoPageModel,
        collectionView: UICollectionView)
}

enum AudioControlBarLayoutState {
    case `default`
    case thin
    case expended
}
