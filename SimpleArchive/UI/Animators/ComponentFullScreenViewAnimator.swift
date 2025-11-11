import UIKit

final class ComponentFullScreenViewAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    static let duration: TimeInterval = 0.3

    private let type: PresentationType

    private let firstViewController: MemoPageViewController
    private let secondViewController: any ComponentFullScreenViewType

    private let toolBarViewRect: CGRect
    private let redCircleRect: CGRect
    private let yellowCircleRect: CGRect
    private let greenCircleRect: CGRect
    private let titleLableRect: CGRect
    private let textViewRect: CGRect
    private let creationLableRect: CGRect
    private let componentInformationViewRect: CGRect

    let redCircle: UIView = {
        let circleView = UIView()
        circleView.backgroundColor = UIColor(red: 0.99, green: 0.27, blue: 0.27, alpha: 1)
        circleView.layer.cornerRadius = 9
        circleView.translatesAutoresizingMaskIntoConstraints = false
        circleView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        circleView.heightAnchor.constraint(equalToConstant: 18).isActive = true
        return circleView
    }()
    let yellowCircle: UIView = {
        let circleView = UIView()
        circleView.backgroundColor = UIColor(red: 1.0, green: 0.69, blue: 0.14, alpha: 1)
        circleView.layer.cornerRadius = 9
        circleView.translatesAutoresizingMaskIntoConstraints = false
        circleView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        circleView.heightAnchor.constraint(equalToConstant: 18).isActive = true
        return circleView
    }()
    let greenCircle: UIView = {
        let circleView = UIView()
        circleView.backgroundColor = UIColor(red: 0.16, green: 0.79, blue: 0.19, alpha: 1)
        circleView.layer.cornerRadius = 9
        circleView.translatesAutoresizingMaskIntoConstraints = false
        circleView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        circleView.heightAnchor.constraint(equalToConstant: 18).isActive = true
        return circleView
    }()

    init?(
        type: PresentationType, firstViewController: MemoPageViewController,
        secondViewController: any ComponentFullScreenViewType
    ) {
        self.type = type
        self.firstViewController = firstViewController
        self.secondViewController = secondViewController

        guard
            let window = firstViewController.view.window ?? secondViewController.getView().window,
            let selectedCell = firstViewController.selectedPageComponentCell
        else { return nil }

        self.toolBarViewRect = selectedCell.toolBarView.convert(selectedCell.toolBarView.bounds, to: window)
        self.redCircleRect = selectedCell.redCircleView.convert(selectedCell.redCircleView.bounds, to: window)
        self.yellowCircleRect = selectedCell.yellowCircleView.convert(selectedCell.yellowCircleView.bounds, to: window)
        self.greenCircleRect = selectedCell.greenCircleView.convert(selectedCell.greenCircleView.bounds, to: window)
        self.titleLableRect = selectedCell.titleLabel.convert(selectedCell.titleLabel.bounds, to: window)
        self.textViewRect = firstViewController.pageComponentContentViewRect!
        self.creationLableRect = selectedCell.creationDateLabel.convert(
            selectedCell.creationDateLabel.bounds, to: window)
        self.componentInformationViewRect = selectedCell.componentInformationView.convert(
            selectedCell.componentInformationView.bounds, to: window)
    }

    deinit { print("Animator deinit") }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        Self.duration
    }

    func presentAnimation(transitionContext: UIViewControllerContextTransitioning) {

        let containerView = transitionContext.containerView

        guard let toView = secondViewController.getView() else {
            transitionContext.completeTransition(false)
            return
        }
        toView.alpha = 0
        containerView.addSubview(toView)

        guard
            firstViewController.selectedPageComponentCell?.toolBarView.snapshotView(afterScreenUpdates: true) != nil,
            let window = firstViewController.view.window ?? secondViewController.getView().window,
            let titleLableSnapshot = secondViewController.titleLabel.snapshotView(afterScreenUpdates: true),
            let creationDateLabelSnapshot = secondViewController
                .creationDateLabel.snapshotView(afterScreenUpdates: true),
            let controllerTextViewSnapshot = secondViewController.getContentView()
                .snapshotView(afterScreenUpdates: true)
        else {
            transitionContext.completeTransition(true)
            return
        }

        let backgroundView: UIView
        let fadeView = UIView(frame: containerView.bounds)
        fadeView.backgroundColor = secondViewController.containerStackView.backgroundColor

        backgroundView = UIView(frame: containerView.bounds)
        backgroundView.addSubview(fadeView)

        fadeView.alpha = 0

        let toolBarView: UIView = {
            let uiview = UIView()
            uiview.backgroundColor = secondViewController.toolbarColor
            uiview.layer.cornerRadius = 10
            uiview.layer.masksToBounds = false
            uiview.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            uiview.frame = self.toolBarViewRect
            return uiview
        }()

        let componentInformationViewSnapshot: UIView = {
            let componentInformationView = UIView()
            componentInformationView.backgroundColor = .systemGray6
            return componentInformationView
        }()

        let textViewWindow: UIView = UIView(frame: self.textViewRect)
        textViewWindow.addSubview(controllerTextViewSnapshot)
        textViewWindow.clipsToBounds = true
        textViewWindow.layer.cornerRadius = 10
        textViewWindow.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        textViewWindow.backgroundColor = .systemGray6

        redCircle.frame = self.redCircleRect
        yellowCircle.frame = self.yellowCircleRect
        greenCircle.frame = self.greenCircleRect
        titleLableSnapshot.frame = self.titleLableRect
        creationDateLabelSnapshot.frame = self.creationLableRect
        componentInformationViewSnapshot.frame = self.componentInformationViewRect

        [
            backgroundView,
            toolBarView, redCircle, yellowCircle, greenCircle,
            titleLableSnapshot, componentInformationViewSnapshot,
            creationDateLabelSnapshot, textViewWindow,
        ]
        .forEach {
            containerView.addSubview($0)
        }

        let controllerToolbarViewRect =
            secondViewController.toolBarView.convert(secondViewController.toolBarView.bounds, to: window)

        let controllerTextViewRect =
            secondViewController.componentContentViewContainer.convert(
                secondViewController.componentContentViewContainer.bounds, to: window)

        let controllerRedCircleRect =
            secondViewController.redCircleView.convert(secondViewController.redCircleView.bounds, to: window)

        let controllerYellowCircleRect =
            secondViewController.yellowCircleView.convert(secondViewController.yellowCircleView.bounds, to: window)

        let controllerGreenCircleRect =
            secondViewController.greenCircleView.convert(secondViewController.greenCircleView.bounds, to: window)

        let controllerCreationLableViewRect =
            secondViewController.creationDateLabel.convert(secondViewController.creationDateLabel.bounds, to: window)

        let controllerTitleLableViewRect =
            secondViewController.titleLabel.convert(secondViewController.titleLabel.bounds, to: window)

        let controllerComponentInformationViewRect =
            secondViewController.componentInformationView.convert(
                secondViewController.componentInformationView.bounds, to: window)

        controllerTextViewSnapshot.alpha = 1
        textViewWindow.alpha = 1

        UIView.animateKeyframes(
            withDuration: Self.duration, delay: 0, options: .calculationModeCubic,
            animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1) {
                    toolBarView.frame = controllerToolbarViewRect

                    self.redCircle.frame = controllerRedCircleRect
                    self.redCircle.backgroundColor = .systemGray5
                    self.yellowCircle.frame = controllerYellowCircleRect
                    self.yellowCircle.backgroundColor = .systemGray5
                    self.greenCircle.frame = controllerGreenCircleRect

                    titleLableSnapshot.frame = controllerTitleLableViewRect
                    creationDateLabelSnapshot.frame = controllerCreationLableViewRect

                    textViewWindow.frame = controllerTextViewRect

                    controllerTextViewSnapshot.frame = CGRect(
                        x: controllerTextViewSnapshot.frame.origin.x + 20,
                        y: controllerTextViewSnapshot.frame.origin.y,
                        width: controllerTextViewSnapshot.frame.width,
                        height: controllerTextViewSnapshot.frame.height
                    )

                    componentInformationViewSnapshot.frame = controllerComponentInformationViewRect

                    textViewWindow.layer.cornerRadius = 0
                    toolBarView.layer.cornerRadius = 0

                    fadeView.alpha = 1
                }
            },
            completion: { _ in
                backgroundView.removeFromSuperview()

                toolBarView.removeFromSuperview()
                titleLableSnapshot.removeFromSuperview()
                creationDateLabelSnapshot.removeFromSuperview()

                textViewWindow.removeFromSuperview()

                componentInformationViewSnapshot.removeFromSuperview()
                controllerTextViewSnapshot.removeFromSuperview()

                toView.alpha = 1

                transitionContext.completeTransition(true)
            }
        )
    }

    func dismissAnimation(transitionContext: UIViewControllerContextTransitioning) {

        let containerView = transitionContext.containerView

        guard
            let window = firstViewController.view.window ?? secondViewController.getView().window,
            let titleLableSnapshot = secondViewController.titleLabel.snapshotView(afterScreenUpdates: true),
            let creationDateLabelSnapshot = secondViewController.creationDateLabel.snapshotView(
                afterScreenUpdates: true),
            let controllerTextViewSnapshot = secondViewController.getContentView()
                .snapshotView(
                    afterScreenUpdates: true)
        else {
            transitionContext.completeTransition(true)
            return
        }

        let backgroundView: UIView
        let fadeView = UIView(frame: containerView.bounds)
        fadeView.backgroundColor = secondViewController.getView().backgroundColor

        backgroundView = firstViewController.view.snapshotView(afterScreenUpdates: true) ?? fadeView
        backgroundView.addSubview(fadeView)

        let controllerTextViewRect = secondViewController.componentContentViewContainer.convert(
            secondViewController.componentContentViewContainer.bounds, to: window)

        let textViewWindow: UIView = UIView(frame: controllerTextViewRect)
        textViewWindow.addSubview(controllerTextViewSnapshot)

        controllerTextViewSnapshot.frame = CGRect(
            x: controllerTextViewSnapshot.frame.origin.x + 20,
            y: controllerTextViewSnapshot.frame.origin.y,
            width: controllerTextViewSnapshot.frame.width,
            height: controllerTextViewSnapshot.frame.height
        )
        textViewWindow.clipsToBounds = true
        textViewWindow.backgroundColor = .systemGray6

        let toolBarView = UIView()
        toolBarView.backgroundColor = secondViewController.toolbarColor

        let componentInformationViewSnapshot: UIView = {
            let componentInformationView = UIView()
            componentInformationView.backgroundColor = .systemGray6
            return componentInformationView
        }()

        let controllerToolbarViewRect =
            secondViewController.toolBarView.convert(secondViewController.toolBarView.bounds, to: window)

        let controllerRedCircleRect =
            secondViewController.redCircleView.convert(secondViewController.redCircleView.bounds, to: window)

        let controllerYellowCircleRect =
            secondViewController.yellowCircleView.convert(secondViewController.yellowCircleView.bounds, to: window)

        let controllerGreenCircleRect =
            secondViewController.greenCircleView.convert(secondViewController.greenCircleView.bounds, to: window)

        let controllerTitleLableRect =
            secondViewController.titleLabel.convert(secondViewController.titleLabel.bounds, to: window)

        let controllerCreationDateLabelRect =
            secondViewController.creationDateLabel.convert(secondViewController.creationDateLabel.bounds, to: window)

        let controllerComponentInformationViewRect =
            secondViewController.componentInformationView.convert(
                secondViewController.componentInformationView.bounds, to: window)

        toolBarView.frame = controllerToolbarViewRect
        componentInformationViewSnapshot.frame = controllerComponentInformationViewRect

        redCircle.frame = controllerRedCircleRect
        redCircle.backgroundColor = .systemGray5
        yellowCircle.frame = controllerYellowCircleRect
        yellowCircle.backgroundColor = .systemGray5
        greenCircle.frame = controllerGreenCircleRect

        titleLableSnapshot.frame = controllerTitleLableRect
        creationDateLabelSnapshot.frame = controllerCreationDateLabelRect

        [
            backgroundView, toolBarView, redCircle, yellowCircle, greenCircle,
            componentInformationViewSnapshot, creationDateLabelSnapshot, titleLableSnapshot, textViewWindow,
        ]
        .forEach {
            containerView.addSubview($0)
        }

        UIView.animateKeyframes(
            withDuration: Self.duration, delay: 0, options: .calculationModeCubic,
            animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1) {

                    toolBarView.frame = self.toolBarViewRect
                    self.redCircle.frame = self.redCircleRect

                    self.redCircle.backgroundColor = UIColor(red: 0.99, green: 0.27, blue: 0.27, alpha: 1)
                    self.yellowCircle.backgroundColor = UIColor(red: 1.0, green: 0.69, blue: 0.14, alpha: 1)

                    self.yellowCircle.frame = self.yellowCircleRect
                    self.greenCircle.frame = self.greenCircleRect

                    titleLableSnapshot.frame = self.titleLableRect
                    creationDateLabelSnapshot.frame = self.creationLableRect

                    textViewWindow.frame = self.textViewRect
                    textViewWindow.clipsToBounds = true
                    textViewWindow.layer.cornerRadius = 10
                    textViewWindow.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
                    controllerTextViewSnapshot.frame = CGRect(
                        x: controllerTextViewSnapshot.frame.origin.x - 20,
                        y: controllerTextViewSnapshot.frame.origin.y,
                        width: controllerTextViewSnapshot.frame.width,
                        height: controllerTextViewSnapshot.frame.height
                    )

                    toolBarView.clipsToBounds = true
                    toolBarView.layer.cornerRadius = 10
                    toolBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

                    componentInformationViewSnapshot.frame = self.componentInformationViewRect

                    fadeView.alpha = 0
                }
            },
            completion: { _ in
                backgroundView.removeFromSuperview()
                toolBarView.removeFromSuperview()
                componentInformationViewSnapshot.removeFromSuperview()

                titleLableSnapshot.removeFromSuperview()
                creationDateLabelSnapshot.removeFromSuperview()

                controllerTextViewSnapshot.removeFromSuperview()

                self.firstViewController.selectedPageComponentCell?
                    .resetupComponentContentViewToDismissFullScreenAnimation()
                self.firstViewController.selectedPageComponentCell = nil

                transitionContext.completeTransition(true)
            }
        )
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        let isPresenting = type.isPresenting

        if isPresenting {
            presentAnimation(transitionContext: transitionContext)
        } else {
            dismissAnimation(transitionContext: transitionContext)
        }
    }
}

enum PresentationType {

    case present, dismiss

    var isPresenting: Bool {
        return self == .present
    }
}
