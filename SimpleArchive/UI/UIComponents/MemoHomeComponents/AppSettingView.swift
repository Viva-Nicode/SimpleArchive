import Combine
import UIKit

final class AppSettingView: UIView, BaseColorUpdatable, UIGestureRecognizerDelegate {
    private let titleLabelView: UIView = {
        let titleLabelView = UIView()
        titleLabelView.layer.shadowColor = UIColor.black.cgColor
        titleLabelView.layer.shadowOffset = .init(width: -4, height: 4)
        titleLabelView.layer.shadowOpacity = 0.1
        titleLabelView.layer.shadowRadius = 4
        titleLabelView.layer.cornerRadius = 15
        titleLabelView.translatesAutoresizingMaskIntoConstraints = false

        let innerShadowLayer = CAShapeLayer()
        let size = CGRect(x: 0, y: 0, width: 130, height: 60)
        innerShadowLayer.frame = size
        titleLabelView.layer.addSublayer(innerShadowLayer)

        let path = UIBezierPath(roundedRect: size.insetBy(dx: -15, dy: -15), cornerRadius: 15)
        let cutout = UIBezierPath(roundedRect: size, cornerRadius: 17).reversing()
        path.append(cutout)

        innerShadowLayer.cornerRadius = 15
        innerShadowLayer.shadowPath = path.cgPath
        innerShadowLayer.shadowOffset = .init(width: -6, height: 6)
        innerShadowLayer.shadowRadius = 4
        innerShadowLayer.masksToBounds = true
        innerShadowLayer.shadowColor = UIColor.black.cgColor
        innerShadowLayer.shadowOpacity = 0.07
        innerShadowLayer.fillRule = .evenOdd

        return titleLabelView
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Setting"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private let settingPageContainerView: UIView = {
        let settingPageContainerView = UIView()
        settingPageContainerView.translatesAutoresizingMaskIntoConstraints = false
        return settingPageContainerView
    }()
    private let signatureSettingView: UIView = {
        let signatureSettingView = UIView()
        signatureSettingView.translatesAutoresizingMaskIntoConstraints = false
        return signatureSettingView
    }()
    private let signatureSettingScrollView: UIScrollView = {
        let signatureSettingScrollView = UIScrollView()
        signatureSettingScrollView.translatesAutoresizingMaskIntoConstraints = false
        signatureSettingScrollView.showsVerticalScrollIndicator = false
        signatureSettingScrollView.showsHorizontalScrollIndicator = false
        signatureSettingScrollView.delaysContentTouches = false
        return signatureSettingScrollView
    }()
    private let noteSettingView: UIView = {
        let noteSettingView = UIView()
        noteSettingView.translatesAutoresizingMaskIntoConstraints = false
        return noteSettingView
    }()
    private let noteSettingScrollView: UIScrollView = {
        let noteSettingScrollView = UIScrollView()
        noteSettingScrollView.translatesAutoresizingMaskIntoConstraints = false
        noteSettingScrollView.showsVerticalScrollIndicator = false
        noteSettingScrollView.showsHorizontalScrollIndicator = false
        noteSettingScrollView.delaysContentTouches = false
        noteSettingScrollView.contentInset = .init(top: 0, left: 0, bottom: 150, right: 0)
        return noteSettingScrollView
    }()
    private let appearanceSettingView: UIView = {
        let appearanceSettingView = UIView()
        appearanceSettingView.translatesAutoresizingMaskIntoConstraints = false
        return appearanceSettingView
    }()
    private let appearanceSettingScrollView: UIScrollView = {
        let appearanceSettingScrollView = UIScrollView()
        appearanceSettingScrollView.translatesAutoresizingMaskIntoConstraints = false
        appearanceSettingScrollView.showsVerticalScrollIndicator = false
        appearanceSettingScrollView.showsHorizontalScrollIndicator = false
        appearanceSettingScrollView.delaysContentTouches = false
        appearanceSettingScrollView.contentInset = .init(top: 0, left: 0, bottom: 150, right: 0)
        return appearanceSettingScrollView
    }()
    private let backgroundBrightnessLabel: UILabel = {
        let backgroundBrightnessLabel = UILabel()
        backgroundBrightnessLabel.text = "Background Brightness"
        backgroundBrightnessLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        backgroundBrightnessLabel.translatesAutoresizingMaskIntoConstraints = false
        return backgroundBrightnessLabel
    }()
    private let tintBrightnessLabel: UILabel = {
        let tintBrightnessLabel = UILabel()
        tintBrightnessLabel.text = "Tint Brightness"
        tintBrightnessLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        tintBrightnessLabel.translatesAutoresizingMaskIntoConstraints = false
        return tintBrightnessLabel
    }()
    private let fastAnimationLabel: UILabel = {
        let fastAnimationLabel = UILabel()
        fastAnimationLabel.text = "Fast Animation"
        fastAnimationLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        fastAnimationLabel.translatesAutoresizingMaskIntoConstraints = false
        return fastAnimationLabel
    }()
    private let toleranceLabel: UILabel = {
        let toleranceLabel = UILabel()
        toleranceLabel.text = "Tolerance"
        toleranceLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        toleranceLabel.translatesAutoresizingMaskIntoConstraints = false
        return toleranceLabel
    }()
    private let signatureCheckToleranceLabel: UILabel = {
        let signatureCheckToleranceLabel = UILabel()
        signatureCheckToleranceLabel.text = "Pattern"
        signatureCheckToleranceLabel.font = .systemFont(ofSize: 15, weight: .thin)
        signatureCheckToleranceLabel.translatesAutoresizingMaskIntoConstraints = false
        return signatureCheckToleranceLabel
    }()
    private let signatureVisibilityLabel: UILabel = {
        let signatureVisibilityLabel = UILabel()
        signatureVisibilityLabel.text = "Position"
        signatureVisibilityLabel.font = .systemFont(ofSize: 15, weight: .thin)
        signatureVisibilityLabel.translatesAutoresizingMaskIntoConstraints = false
        return signatureVisibilityLabel
    }()
    private let signtureAdjustGuideLabel: UILabel = {
        let signtureAdjustGuideLabel = UILabel()
        signtureAdjustGuideLabel.text =
            """
            As you move to the right, the signature position is checked more strictly,
            and as you move downward, the pattern is checked more strictly.
            If the signature has a simple pattern, loose matching settings may allow similar patterns to unlock it easily.
            Also, if the signature has a complex pattern,
            strict matching settings may make it difficult to unlock even with signatures that appear identical.
            """
        signtureAdjustGuideLabel.numberOfLines = 0
        signtureAdjustGuideLabel.font = .systemFont(ofSize: 14)
        signtureAdjustGuideLabel.translatesAutoresizingMaskIntoConstraints = false
        return signtureAdjustGuideLabel
    }()
    private let signatureBenchMarkLabel: UILabel = {
        let signatureBenchMarkLabel = UILabel()
        signatureBenchMarkLabel.text = "BenchMark Visibility"
        signatureBenchMarkLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        signatureBenchMarkLabel.translatesAutoresizingMaskIntoConstraints = false
        return signatureBenchMarkLabel
    }()
    private let textMemoSummarizationLabel: UILabel = {
        let textMemoSummaryLabel = UILabel()
        textMemoSummaryLabel.text = "Text Memo Summarization"
        textMemoSummaryLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        textMemoSummaryLabel.translatesAutoresizingMaskIntoConstraints = false
        return textMemoSummaryLabel
    }()
    private let drawingDisplayLabel: UILabel = {
        let drawingDisplayLabel = UILabel()
        drawingDisplayLabel.text = "Drawing Display"
        drawingDisplayLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        drawingDisplayLabel.translatesAutoresizingMaskIntoConstraints = false
        return drawingDisplayLabel
    }()
    private let resetButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Reset Signature"
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .systemPink
        config.cornerStyle = .capsule
        var titleAttr = AttributedString("Reset Signature")
        titleAttr.font = .systemFont(ofSize: 21, weight: .semibold)
        config.attributedTitle = titleAttr

        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private let blockPersonImageView: UIImageView = {
        let personXImgae = UIImage(named: "xmark_person")?
            .resized(to: CGSize(width: 100, height: 100))
            .withRenderingMode(.alwaysTemplate)

        let blockPersonImageView = UIImageView(image: personXImgae)
        blockPersonImageView.image = personXImgae
        blockPersonImageView.translatesAutoresizingMaskIntoConstraints = false
        return blockPersonImageView
    }()
    private let signatureSettingBlockGuideLabel: UILabel = {
        let signatureSettingBlockGuideLabel = UILabel()
        signatureSettingBlockGuideLabel.text = "Can be configured after unlocking the private directory."
        signatureSettingBlockGuideLabel.textAlignment = .center
        signatureSettingBlockGuideLabel.numberOfLines = 2
        signatureSettingBlockGuideLabel.font = .systemFont(ofSize: 18)
        signatureSettingBlockGuideLabel.translatesAutoresizingMaskIntoConstraints = false
        return signatureSettingBlockGuideLabel
    }()
    private let signatureSettingEditBlockView: UIView = {
        let signatureSettingEditBlockView = UIView()
        signatureSettingEditBlockView.translatesAutoresizingMaskIntoConstraints = false
        return signatureSettingEditBlockView
    }()
    private(set) var settingCategoryTab = SettingCategoryTabView()
    private lazy var backgroundBrightnessSlider = AppBaseColorBrightnessSlider(
        minValue: 0.3, maxValue: 0.9, currentValue: AppAppearanceManager.shared.appBaseColorBrightness
    ) { brightness in
        AppAppearanceManager.shared.appBaseColorBrightness = brightness
        self.applyColor()
    } end: { brigntness in
        guard let window = self.window else { return }
        UIView.transition(with: window, duration: 0.2, options: .transitionCrossDissolve) {
            window.overrideUserInterfaceStyle = brigntness <= 0.4 ? .dark : .light
        }
    }
    private lazy var tintBrightnessSlider = AppBaseColorBrightnessSlider(
        minValue: 0.0, maxValue: 0.9, currentValue: AppAppearanceManager.shared.appTintColorBrightness
    ) { brightness in
        AppAppearanceManager.shared.appTintColorBrightness = brightness
        self.applyColor()
    }
    private(set) var toleranceAdjustingView = SignatureToleranceAdjustingView()
    private(set) var benchMarkVisibilityToggleView = SignatureBenchMarkVisibilityToggleView()
    private(set) var displaySegmentedSelectorView = SignatureDisplaySegmentedSelectorView()
    private(set) var fastAnimationToggleView = ActivationToggleView()
    private(set) var textMemoSummerizationToggle = ActivationToggleView()

    private var moveSettingCategoryPanGesture: UIPanGestureRecognizer!
    private var moveSettingCategoryAnimator: UIViewPropertyAnimator?

    private var panStartPoint: CGPoint?
    private var settingCategoryOrder: [UIScrollView] = []
    private var settingCategoryIndex = 0
    private var panDirection: PanDirection?
    var dispatcher: PassthroughSubject<MemoHomeViewInput, Never>? {
        didSet {
            toleranceAdjustingView.dispatcher = dispatcher
            displaySegmentedSelectorView.dispatcher = dispatcher
            benchMarkVisibilityToggleView.dispatcher = dispatcher
        }
    }

    init() {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        isHidden = true
        alpha = 0
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabelView)
        titleLabelView.addSubview(titleLabel)

        addSubview(settingCategoryTab)
        addSubview(settingPageContainerView)

        settingPageContainerView.addSubview(appearanceSettingScrollView)
        appearanceSettingScrollView.addSubview(appearanceSettingView)

        settingPageContainerView.addSubview(noteSettingScrollView)
        noteSettingScrollView.addSubview(noteSettingView)

        settingPageContainerView.addSubview(signatureSettingScrollView)
        signatureSettingScrollView.addSubview(signatureSettingView)
        signatureSettingScrollView.addSubview(signatureSettingEditBlockView)

        signatureSettingEditBlockView.addSubview(signatureSettingBlockGuideLabel)
        signatureSettingEditBlockView.addSubview(blockPersonImageView)

        appearanceSettingView.addSubview(backgroundBrightnessLabel)
        appearanceSettingView.addSubview(tintBrightnessLabel)
        appearanceSettingView.addSubview(backgroundBrightnessSlider)
        appearanceSettingView.addSubview(tintBrightnessSlider)
        appearanceSettingView.addSubview(fastAnimationLabel)
        appearanceSettingView.addSubview(fastAnimationToggleView)

        noteSettingView.addSubview(textMemoSummarizationLabel)
        noteSettingView.addSubview(textMemoSummerizationToggle)

        noteSettingScrollView.alpha = 0
        signatureSettingScrollView.alpha = 0

        moveSettingCategoryPanGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction))
        moveSettingCategoryPanGesture.delegate = self
        moveSettingCategoryPanGesture.delaysTouchesBegan = false
        addGestureRecognizer(moveSettingCategoryPanGesture)

        settingCategoryOrder = [appearanceSettingScrollView, noteSettingScrollView, signatureSettingScrollView]

        resetButton.addAction(UIAction { _ in self.dispatcher?.send(.willResetSignature) }, for: .touchUpInside)

        fastAnimationToggleView.setupGesture {
            AppAppearanceManager.shared.animaDuration =
                AppAppearanceManager.shared.animaDuration == .fast ? .normal : .fast
        }

        textMemoSummerizationToggle.setupGesture {
            self.dispatcher?.send(.willSetTextMemoSermmerizationEnable)
        }

        applyColor()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabelView.heightAnchor.constraint(equalToConstant: 60),
            titleLabelView.widthAnchor.constraint(equalToConstant: 130),
            titleLabelView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabelView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),

            titleLabel.centerXAnchor.constraint(equalTo: titleLabelView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: titleLabelView.centerYAnchor),

            settingCategoryTab.topAnchor.constraint(equalTo: titleLabelView.bottomAnchor),
            settingCategoryTab.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            settingCategoryTab.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            settingCategoryTab.heightAnchor.constraint(equalToConstant: 60),

            settingPageContainerView.topAnchor.constraint(equalTo: settingCategoryTab.bottomAnchor, constant: 20),
            settingPageContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            settingPageContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            settingPageContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // MARK: ============================ appearance ============================

            appearanceSettingScrollView.topAnchor.constraint(equalTo: settingPageContainerView.topAnchor),
            appearanceSettingScrollView.leadingAnchor.constraint(equalTo: settingPageContainerView.leadingAnchor),
            appearanceSettingScrollView.trailingAnchor.constraint(equalTo: settingPageContainerView.trailingAnchor),
            appearanceSettingScrollView.bottomAnchor.constraint(equalTo: settingPageContainerView.bottomAnchor),

            appearanceSettingView.topAnchor.constraint(
                equalTo: appearanceSettingScrollView.contentLayoutGuide.topAnchor),
            appearanceSettingView.trailingAnchor.constraint(
                equalTo: appearanceSettingScrollView.contentLayoutGuide.trailingAnchor),
            appearanceSettingView.leadingAnchor.constraint(
                equalTo: appearanceSettingScrollView.contentLayoutGuide.leadingAnchor),
            appearanceSettingView.bottomAnchor.constraint(
                equalTo: appearanceSettingScrollView.contentLayoutGuide.bottomAnchor),
            appearanceSettingView.widthAnchor.constraint(
                equalTo: appearanceSettingScrollView.frameLayoutGuide.widthAnchor),
            appearanceSettingView.heightAnchor.constraint(
                equalTo: appearanceSettingScrollView.contentLayoutGuide.heightAnchor),

            backgroundBrightnessLabel.topAnchor.constraint(equalTo: appearanceSettingView.topAnchor),
            backgroundBrightnessLabel.leadingAnchor.constraint(equalTo: appearanceSettingView.leadingAnchor),

            backgroundBrightnessSlider.topAnchor.constraint(
                equalTo: backgroundBrightnessLabel.bottomAnchor, constant: 8),
            backgroundBrightnessSlider.leadingAnchor.constraint(equalTo: appearanceSettingView.leadingAnchor),

            tintBrightnessLabel.topAnchor.constraint(equalTo: backgroundBrightnessSlider.bottomAnchor, constant: 35),
            tintBrightnessLabel.leadingAnchor.constraint(equalTo: appearanceSettingView.leadingAnchor),

            tintBrightnessSlider.topAnchor.constraint(equalTo: tintBrightnessLabel.bottomAnchor, constant: 8),
            tintBrightnessSlider.leadingAnchor.constraint(equalTo: appearanceSettingView.leadingAnchor),

            fastAnimationLabel.topAnchor.constraint(equalTo: tintBrightnessSlider.bottomAnchor, constant: 30),
            fastAnimationLabel.leadingAnchor.constraint(equalTo: appearanceSettingView.leadingAnchor),

            fastAnimationToggleView.topAnchor.constraint(equalTo: fastAnimationLabel.bottomAnchor, constant: 8),
            fastAnimationToggleView.leadingAnchor.constraint(equalTo: appearanceSettingView.leadingAnchor),
            fastAnimationToggleView.bottomAnchor.constraint(equalTo: appearanceSettingView.bottomAnchor),

            // MARK: ============================ note ============================

            noteSettingScrollView.topAnchor.constraint(equalTo: settingPageContainerView.topAnchor),
            noteSettingScrollView.leadingAnchor.constraint(equalTo: settingPageContainerView.leadingAnchor),
            noteSettingScrollView.trailingAnchor.constraint(equalTo: settingPageContainerView.trailingAnchor),
            noteSettingScrollView.bottomAnchor.constraint(equalTo: settingPageContainerView.bottomAnchor),

            noteSettingView.topAnchor.constraint(
                equalTo: noteSettingScrollView.contentLayoutGuide.topAnchor),
            noteSettingView.trailingAnchor.constraint(
                equalTo: noteSettingScrollView.contentLayoutGuide.trailingAnchor),
            noteSettingView.leadingAnchor.constraint(
                equalTo: noteSettingScrollView.contentLayoutGuide.leadingAnchor),
            noteSettingView.bottomAnchor.constraint(
                equalTo: noteSettingScrollView.contentLayoutGuide.bottomAnchor),
            noteSettingView.widthAnchor.constraint(
                equalTo: noteSettingScrollView.frameLayoutGuide.widthAnchor),
            noteSettingView.heightAnchor.constraint(
                equalTo: noteSettingScrollView.contentLayoutGuide.heightAnchor),

            textMemoSummarizationLabel.topAnchor.constraint(equalTo: noteSettingView.topAnchor),
            textMemoSummarizationLabel.leadingAnchor.constraint(equalTo: noteSettingView.leadingAnchor),

            textMemoSummerizationToggle.topAnchor.constraint(
                equalTo: textMemoSummarizationLabel.bottomAnchor, constant: 8),
            textMemoSummerizationToggle.leadingAnchor.constraint(equalTo: noteSettingView.leadingAnchor),
            textMemoSummerizationToggle.bottomAnchor.constraint(equalTo: noteSettingView.bottomAnchor),

            // MARK: ============================ signatrue ============================

            signatureSettingScrollView.topAnchor.constraint(equalTo: settingPageContainerView.topAnchor),
            signatureSettingScrollView.leadingAnchor.constraint(equalTo: settingPageContainerView.leadingAnchor),
            signatureSettingScrollView.trailingAnchor.constraint(equalTo: settingPageContainerView.trailingAnchor),
            signatureSettingScrollView.bottomAnchor.constraint(equalTo: settingPageContainerView.bottomAnchor),

            signatureSettingView.topAnchor.constraint(
                equalTo: signatureSettingScrollView.contentLayoutGuide.topAnchor),
            signatureSettingView.trailingAnchor.constraint(
                equalTo: signatureSettingScrollView.contentLayoutGuide.trailingAnchor),
            signatureSettingView.leadingAnchor.constraint(
                equalTo: signatureSettingScrollView.contentLayoutGuide.leadingAnchor),
            signatureSettingView.bottomAnchor.constraint(
                equalTo: signatureSettingScrollView.contentLayoutGuide.bottomAnchor),
            signatureSettingView.widthAnchor.constraint(
                equalTo: signatureSettingScrollView.frameLayoutGuide.widthAnchor),
            signatureSettingView.heightAnchor.constraint(
                equalTo: signatureSettingScrollView.contentLayoutGuide.heightAnchor),

            signatureSettingEditBlockView.topAnchor.constraint(
                equalTo: signatureSettingScrollView.frameLayoutGuide.topAnchor),
            signatureSettingEditBlockView.leadingAnchor.constraint(
                equalTo: signatureSettingScrollView.leadingAnchor),
            signatureSettingEditBlockView.widthAnchor.constraint(
                equalTo: signatureSettingScrollView.frameLayoutGuide.widthAnchor),
            signatureSettingEditBlockView.heightAnchor.constraint(
                equalTo: signatureSettingScrollView.frameLayoutGuide.heightAnchor),

            blockPersonImageView.centerXAnchor.constraint(
                equalTo: signatureSettingEditBlockView.centerXAnchor),
            blockPersonImageView.bottomAnchor.constraint(
                equalTo: signatureSettingBlockGuideLabel.topAnchor, constant: -10),

            signatureSettingBlockGuideLabel.widthAnchor.constraint(
                equalTo: signatureSettingEditBlockView.widthAnchor, multiplier: 0.9),
            signatureSettingBlockGuideLabel.centerXAnchor.constraint(
                equalTo: signatureSettingEditBlockView.centerXAnchor),
            signatureSettingBlockGuideLabel.centerYAnchor.constraint(
                equalTo: signatureSettingEditBlockView.centerYAnchor),
        ])
    }

    private func setMoveSettingCategoryAnimate() {
        guard let panDirection else { return }
        let timing = UISpringTimingParameters(mass: 0.3, stiffness: 100, damping: 12, initialVelocity: .zero)
        moveSettingCategoryAnimator = UIViewPropertyAnimator(duration: 0, timingParameters: timing)
        let currentIndex = settingCategoryIndex
        var nextIndex: Int

        switch panDirection {
            case .left:
                nextIndex = currentIndex + 1 >= settingCategoryOrder.count ? 0 : currentIndex + 1
                settingCategoryOrder[nextIndex].transform = .init(translationX: bounds.width, y: 0)

            case .right:
                nextIndex = currentIndex - 1 < 0 ? settingCategoryOrder.count - 1 : currentIndex - 1
                settingCategoryOrder[nextIndex].transform = .init(translationX: -bounds.width, y: 0)
        }

        moveSettingCategoryAnimator?
            .addAnimations { [self] in
                settingCategoryOrder[currentIndex].transform = .init(
                    translationX: bounds.width * (panDirection == .right ? 1 : -1), y: 0)
                settingCategoryOrder[currentIndex].alpha = 0

                settingCategoryOrder[nextIndex].transform = .identity
                settingCategoryOrder[nextIndex].alpha = 1

                settingCategoryTab.selectTab(forPageIndex: nextIndex)
                layoutIfNeeded()
            }

        moveSettingCategoryAnimator?
            .addCompletion { position in
                var selectedIndex = currentIndex
                switch position {
                    case .end:
                        self.settingCategoryIndex = nextIndex
                        selectedIndex = nextIndex
                        self.settingCategoryOrder.forEach { $0.contentOffset.y = 0 }
                    case .start, .current: break
                    @unknown default: break
                }
                UIView.performWithoutAnimation {
                    self.settingCategoryTab.selectTab(forPageIndex: selectedIndex)
                    self.settingCategoryOrder[currentIndex].transform = .identity
                    self.settingCategoryOrder[currentIndex].alpha = selectedIndex == currentIndex ? 1 : 0
                    self.settingCategoryOrder[nextIndex].transform = .identity
                    self.settingCategoryOrder[nextIndex].alpha = selectedIndex == nextIndex ? 1 : 0
                    self.layoutIfNeeded()
                }
                self.moveSettingCategoryPanGesture.isEnabled = true
                self.settingCategoryOrder.forEach { $0.isScrollEnabled = true }
            }

        moveSettingCategoryAnimator?.startAnimation()
        moveSettingCategoryAnimator?.pauseAnimation()
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        guard let moveSettingCategoryPanGesture, gestureRecognizer === moveSettingCategoryPanGesture else {
            return true
        }
        return !isTouchInsideBrightnessSlider(touch)
    }

    private func isTouchInsideBrightnessSlider(_ touch: UITouch) -> Bool {
        [backgroundBrightnessSlider, tintBrightnessSlider, toleranceAdjustingView]
            .contains { slider in
                let location = touch.location(in: slider)
                return slider.point(inside: location, with: nil)
            }
    }

    @objc func panGestureAction(_ sender: UIPanGestureRecognizer) {
        let currentPoint = sender.location(in: self)
        let velocity = sender.velocity(in: self)

        switch sender.state {
            case .began:
                moveSettingCategoryAnimator = nil
                panDirection = nil
                panStartPoint = currentPoint

            case .changed:
                guard let start = panStartPoint else { return }
                let deltaX = currentPoint.x - start.x
                let progress = min(max(abs(deltaX) / bounds.width, 0), 1)

                if panDirection == nil {
                    panDirection = deltaX > 0 ? .right : .left
                    setMoveSettingCategoryAnimate()
                } else {
                    if (deltaX > 0 ? .right : .left) != panDirection! {
                        moveSettingCategoryAnimator?.stopAnimation(false)
                        moveSettingCategoryAnimator?.finishAnimation(at: .current)
                        moveSettingCategoryAnimator = nil
                        panDirection = nil
                    }
                }

                moveSettingCategoryAnimator?.fractionComplete = progress

            case .ended:
                guard let start = panStartPoint else { return }
                if panDirection != nil {
                    let deltaY = abs(currentPoint.x - start.x)
                    gestureComplete(deltaY: deltaY, isFast: velocity.x.magnitude >= 300)
                }

            case .cancelled, .failed:
                if panDirection != nil {
                    gestureComplete(deltaY: 0, isFast: false)
                }

            default:
                break
        }
    }

    private func gestureComplete(deltaY: CGFloat, isFast: Bool) {
        moveSettingCategoryPanGesture.isEnabled = false
        settingCategoryOrder.forEach { $0.isScrollEnabled = false }
        if deltaY >= bounds.width * 0.3 || isFast {
            moveSettingCategoryAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 1)
        } else {
            moveSettingCategoryAnimator?.isReversed = true
            moveSettingCategoryAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 1)
        }
    }

    func setEditable(_ isUnlocked: Bool) {
        if isUnlocked {
            signatureSettingScrollView.contentOffset.y = 0
            signatureSettingEditBlockView.removeFromSuperview()

            signatureSettingView.addSubview(toleranceLabel)
            signatureSettingView.addSubview(toleranceAdjustingView)
            signatureSettingView.addSubview(signatureCheckToleranceLabel)
            signatureSettingView.addSubview(signatureVisibilityLabel)
            signatureSettingView.addSubview(signtureAdjustGuideLabel)
            signatureSettingView.addSubview(drawingDisplayLabel)
            signatureSettingView.addSubview(displaySegmentedSelectorView)
            signatureSettingView.addSubview(signatureBenchMarkLabel)
            signatureSettingView.addSubview(benchMarkVisibilityToggleView)
            signatureSettingView.addSubview(resetButton)

            NSLayoutConstraint.activate([
                toleranceLabel.topAnchor.constraint(equalTo: signatureSettingView.topAnchor),
                toleranceLabel.leadingAnchor.constraint(equalTo: signatureSettingView.leadingAnchor),

                toleranceAdjustingView.widthAnchor.constraint(equalToConstant: 170),
                toleranceAdjustingView.heightAnchor.constraint(equalToConstant: 170),
                toleranceAdjustingView.topAnchor.constraint(equalTo: toleranceLabel.bottomAnchor, constant: 10),
                toleranceAdjustingView.leadingAnchor.constraint(equalTo: signatureSettingView.leadingAnchor),

                signatureCheckToleranceLabel.centerXAnchor.constraint(equalTo: toleranceAdjustingView.centerXAnchor),
                signatureCheckToleranceLabel.topAnchor.constraint(
                    equalTo: toleranceAdjustingView.bottomAnchor, constant: 5),

                signatureVisibilityLabel.leadingAnchor.constraint(
                    equalTo: toleranceAdjustingView.trailingAnchor, constant: 5),
                signatureVisibilityLabel.centerYAnchor.constraint(equalTo: toleranceAdjustingView.centerYAnchor),

                signtureAdjustGuideLabel.topAnchor.constraint(
                    equalTo: signatureCheckToleranceLabel.bottomAnchor, constant: 20),
                signtureAdjustGuideLabel.leadingAnchor.constraint(equalTo: signatureSettingView.leadingAnchor),
                signtureAdjustGuideLabel.widthAnchor.constraint(equalTo: signatureSettingScrollView.widthAnchor),

                drawingDisplayLabel.topAnchor.constraint(equalTo: signtureAdjustGuideLabel.bottomAnchor, constant: 25),
                drawingDisplayLabel.heightAnchor.constraint(equalToConstant: 30),
                drawingDisplayLabel.leadingAnchor.constraint(equalTo: signatureSettingView.leadingAnchor),

                displaySegmentedSelectorView.topAnchor.constraint(
                    equalTo: drawingDisplayLabel.bottomAnchor, constant: 10),
                displaySegmentedSelectorView.leadingAnchor.constraint(equalTo: signatureSettingView.leadingAnchor),

                signatureBenchMarkLabel.topAnchor.constraint(
                    equalTo: displaySegmentedSelectorView.bottomAnchor, constant: 25),
                signatureBenchMarkLabel.heightAnchor.constraint(equalToConstant: 30),
                signatureBenchMarkLabel.leadingAnchor.constraint(equalTo: signatureSettingView.leadingAnchor),

                benchMarkVisibilityToggleView.topAnchor.constraint(
                    equalTo: signatureBenchMarkLabel.bottomAnchor, constant: 10),
                benchMarkVisibilityToggleView.leadingAnchor.constraint(equalTo: signatureSettingView.leadingAnchor),
                benchMarkVisibilityToggleView.widthAnchor.constraint(equalToConstant: 170),
                benchMarkVisibilityToggleView.heightAnchor.constraint(equalToConstant: 50),

                resetButton.topAnchor.constraint(equalTo: benchMarkVisibilityToggleView.bottomAnchor, constant: 25),
                resetButton.widthAnchor.constraint(equalToConstant: 200),
                resetButton.heightAnchor.constraint(equalToConstant: 50),
                resetButton.leadingAnchor.constraint(equalTo: signatureSettingView.leadingAnchor),
                resetButton.bottomAnchor.constraint(equalTo: signatureSettingView.bottomAnchor, constant: -150),
            ])
            layoutIfNeeded()
        }
    }

    func applyColor(_ colorManager: any AppAppearanceManagerType = AppAppearanceManager.shared) {
        backgroundColor = colorManager.appBaseColor
        appearanceSettingScrollView.backgroundColor = colorManager.appBaseColor
        noteSettingScrollView.backgroundColor = colorManager.appBaseColor
        signatureSettingScrollView.backgroundColor = colorManager.appBaseColor
        titleLabelView.backgroundColor = colorManager.appBaseColor
        titleLabel.textColor = colorManager.appTintColor
        backgroundBrightnessLabel.textColor = colorManager.appTintColor
        tintBrightnessLabel.textColor = colorManager.appTintColor
        fastAnimationLabel.textColor = colorManager.appTintColor
        toleranceLabel.textColor = colorManager.appTintColor
        signatureCheckToleranceLabel.textColor = colorManager.appTintColor
        signatureVisibilityLabel.textColor = colorManager.appTintColor
        signtureAdjustGuideLabel.textColor = colorManager.appTintColor
        signatureBenchMarkLabel.textColor = colorManager.appTintColor
        textMemoSummarizationLabel.textColor = colorManager.appTintColor
        drawingDisplayLabel.textColor = colorManager.appTintColor
        signatureSettingBlockGuideLabel.textColor = colorManager.appTintColor
        blockPersonImageView.tintColor = colorManager.appTintColor
        fastAnimationToggleView.whiteInnerShadowLayer.shadowOpacity = Float(colorManager.appBaseColorBrightness - 0.25)
        fastAnimationToggleView.thumbInnerWhiteShadowLayer.shadowOpacity = Float(
            colorManager.appBaseColorBrightness - 0.25)
        textMemoSummerizationToggle.whiteInnerShadowLayer.shadowOpacity = Float(
            colorManager.appBaseColorBrightness - 0.25)
        textMemoSummerizationToggle.thumbInnerWhiteShadowLayer.shadowOpacity = Float(
            colorManager.appBaseColorBrightness - 0.25)
        displaySegmentedSelectorView.innerWhiteShadowLayer.shadowOpacity = Float(
            colorManager.appBaseColorBrightness - 0.25)
        toleranceAdjustingView.innerWhiteShadowLayer.shadowOpacity = Float(colorManager.appBaseColorBrightness - 0.25)
        benchMarkVisibilityToggleView.innerWhiteShadowLayer.shadowOpacity = Float(
            colorManager.appBaseColorBrightness - 0.25)
        (parentViewController as? MemoHomeViewController)?.applyColor()
        settingCategoryTab.applyColor()
    }

    private enum PanDirection {
        case left
        case right
    }
}
