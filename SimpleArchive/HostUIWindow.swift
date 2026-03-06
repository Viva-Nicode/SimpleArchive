import Combine
import UIKit

final class HostUIWindow: UIWindow, AudioControlBarHost {
    var strategy: (any AudioControlBarActionStrategy)?
    var thumnbnaleTapActionSubscription: AnyCancellable?

    private let outerAudioControlBarHeight: CGFloat = 92
    private let defaultTransitionDuration: TimeInterval = 0.35
    private(set) var audioControlBar: AudioControlBarView
    private var regularAudioControlBarConstraints: [NSLayoutConstraint] = []
    private var outerAudioControlBarConstraints: [NSLayoutConstraint] = []
    private var isOuterLayoutApplied = false

    override init(windowScene: UIWindowScene) {
        audioControlBar = AudioControlBarView()

        super.init(windowScene: windowScene)

        addSubview(audioControlBar)

        regularAudioControlBarConstraints = [
            audioControlBar.widthAnchor.constraint(equalToConstant: UIConstants.audioControlBarViewWidth),
            audioControlBar.heightAnchor.constraint(equalToConstant: UIConstants.audioControlBarViewHeight),
            audioControlBar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            audioControlBar.centerXAnchor.constraint(equalTo: centerXAnchor),
        ]
		
        NSLayoutConstraint.activate(regularAudioControlBarConstraints)

        outerAudioControlBarConstraints = [
            audioControlBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            audioControlBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            audioControlBar.heightAnchor.constraint(equalToConstant: outerAudioControlBarHeight),
            audioControlBar.bottomAnchor.constraint(equalTo: bottomAnchor),
        ]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setStrategy(st: AudioControlBarActionStrategy) {
        restoreInnerLayoutIfNeeded(coordinatedBy: nil)
        strategy = nil
        strategy = st
    }

    func setStrategy(
        st: AudioControlBarActionStrategy,
        coordinatedBy coordinator: UIViewControllerTransitionCoordinator?
    ) {
        restoreInnerLayoutIfNeeded(coordinatedBy: coordinator)
        strategy = nil
        strategy = st
    }

    func transformOuter() {
        transformOuter(coordinatedBy: nil)
    }

    func transformOuter(coordinatedBy coordinator: UIViewControllerTransitionCoordinator?) {
        guard !isOuterLayoutApplied else { return }

        //        bringSubviewToFront(audioControlBar)
        //        layoutIfNeeded()
        //        audioControlBar.layoutIfNeeded()

        isOuterLayoutApplied = true

        let applyOuterLayoutAndStyle: () -> Void = {
            NSLayoutConstraint.deactivate(self.regularAudioControlBarConstraints)
            NSLayoutConstraint.activate(self.outerAudioControlBarConstraints)
            self.audioControlBar.transformeOuter(layoutImmediately: false)
        }
        let prepareRollbackToInner: () -> Void = {
            self.isOuterLayoutApplied = false
            NSLayoutConstraint.deactivate(self.outerAudioControlBarConstraints)
            NSLayoutConstraint.activate(self.regularAudioControlBarConstraints)
            self.audioControlBar.restoreFromOuterTransform(layoutImmediately: false)
        }
        let finalizeInnerRollback: () -> Void = {
            self.audioControlBar.finalizeInnerTransform()
            self.layoutIfNeeded()
            self.audioControlBar.layoutIfNeeded()
        }

        if let coordinator {
            var didHandleInteractionCancellation = false
            coordinator.notifyWhenInteractionChanges { context in
                guard context.isCancelled else { return }
                didHandleInteractionCancellation = true
                prepareRollbackToInner()
            }

            coordinator.animate(
                alongsideTransition: { _ in
                    applyOuterLayoutAndStyle()
                    self.layoutIfNeeded()
                    self.audioControlBar.layoutIfNeeded()
                },
                completion: { context in
                    if context.isCancelled {
                        if !didHandleInteractionCancellation {
                            prepareRollbackToInner()
                        } else {
                            finalizeInnerRollback()
                        }
                    } else {
                        self.audioControlBar.finalizeOuterTransform()
                    }
                }
            )
        } else {
            UIView.animate(
                withDuration: defaultTransitionDuration,
                delay: 0,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: 0.2,
                options: [.curveEaseInOut, .allowUserInteraction]
            ) {
                applyOuterLayoutAndStyle()
                self.layoutIfNeeded()
                self.audioControlBar.layoutIfNeeded()
            } completion: { _ in
                self.audioControlBar.finalizeOuterTransform()
            }
        }
    }

    private func restoreInnerLayoutIfNeeded(coordinatedBy coordinator: UIViewControllerTransitionCoordinator?) {
        guard isOuterLayoutApplied else { return }

        //        bringSubviewToFront(audioControlBar)
        //        layoutIfNeeded()
        //        audioControlBar.layoutIfNeeded()

        isOuterLayoutApplied = false
		
        let applyRegularLayoutAndStyle: () -> Void = {
            NSLayoutConstraint.deactivate(self.outerAudioControlBarConstraints)
            NSLayoutConstraint.activate(self.regularAudioControlBarConstraints)
            self.audioControlBar.restoreFromOuterTransform(layoutImmediately: false)
        }
        let prepareRollbackToOuter: () -> Void = {
            self.isOuterLayoutApplied = true
            NSLayoutConstraint.deactivate(self.regularAudioControlBarConstraints)
            NSLayoutConstraint.activate(self.outerAudioControlBarConstraints)
            self.audioControlBar.transformeOuter(layoutImmediately: false)
        }
        let finalizeOuterRollback: () -> Void = {
            self.audioControlBar.finalizeOuterTransform()
            self.layoutIfNeeded()
            self.audioControlBar.layoutIfNeeded()
        }

        if let coordinator {
            var didHandleInteractionCancellation = false
            coordinator.notifyWhenInteractionChanges { context in
                guard context.isCancelled else { return }
                didHandleInteractionCancellation = true
                prepareRollbackToOuter()
            }

            coordinator.animate(
                alongsideTransition: { _ in
                    applyRegularLayoutAndStyle()
                    self.layoutIfNeeded()
                    self.audioControlBar.layoutIfNeeded()
                },
                completion: { context in
                    if context.isCancelled {
                        if !didHandleInteractionCancellation {
                            prepareRollbackToOuter()
                        } else {
                            finalizeOuterRollback()
                        }
                    } else {
                        self.audioControlBar.finalizeInnerTransform()
                    }
                }
            )
        } else {
            UIView.animate(
                withDuration: defaultTransitionDuration,
                delay: 0,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: 0.2,
                options: [.curveEaseInOut, .allowUserInteraction]
            ) {
                applyRegularLayoutAndStyle()
                self.layoutIfNeeded()
                self.audioControlBar.layoutIfNeeded()
            } completion: { _ in
                self.audioControlBar.finalizeInnerTransform()
            }
        }
    }
}
