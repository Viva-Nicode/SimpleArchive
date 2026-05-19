import Combine
import UIKit

final class PrivateDirectoryBlockView: UIView, BaseColorUpdatable {
    private(set) var privateDirectoryBlockCommentLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 25, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private let getStartButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Get Start"
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .systemBlue
        config.cornerStyle = .capsule
        var titleAttr = AttributedString("Get Start")
        titleAttr.font = .systemFont(ofSize: 21, weight: .semibold)
        config.attributedTitle = titleAttr

        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private let DoneButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Done"
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .systemBlue
        config.cornerStyle = .capsule
        var titleAttr = AttributedString("Done")
        titleAttr.font = .systemFont(ofSize: 21, weight: .semibold)
        config.attributedTitle = titleAttr

        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private let finishButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Finish"
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .systemBlue
        config.cornerStyle = .capsule
        var titleAttr = AttributedString("Finish")
        titleAttr.font = .systemFont(ofSize: 21, weight: .semibold)
        config.attributedTitle = titleAttr

        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private let alertLabel: UILabel = {
        let alertLabel = UILabel()
        alertLabel.textColor = .systemRed
        alertLabel.font = .systemFont(ofSize: 19, weight: .semibold)
        alertLabel.numberOfLines = 0
        alertLabel.translatesAutoresizingMaskIntoConstraints = false
        alertLabel.textAlignment = .center
        return alertLabel
    }()
    private let unregisterButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Unregister"
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .systemPink
        config.cornerStyle = .capsule
        var titleAttr = AttributedString("Unregister")
        titleAttr.font = .systemFont(ofSize: 21, weight: .semibold)
        config.attributedTitle = titleAttr

        let button = UIButton(configuration: config)
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.backgroundColor = .systemRed
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.textAlignment = .center
        label.layer.cornerRadius = 15
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private(set) lazy var signatureRegisterGuideLabel: UILabel = {
        let infoLabel = UILabel()
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.numberOfLines = 0

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.alignment = .left

        let sentences = [
            "Signature registration is required to access the private folder.",
            "At least 8 signatures must be registered, and more than 15 registrations are recommended.",
            "Signing can be done anywhere on the screen, but signing near the center is recommended.",
            "Each signature does not need to be exactly identical, but the pattern or characteristics should be consistent.",
            "Each signature should be made in the same position and at the same size.",
            "Tap the button to the left of the Finish button and swipe left or right to view or unregister the registered signatures.",
        ]

        for (i, sentence) in sentences.enumerated() {
            signatureRegisterGuideAttrString.append(
                NSAttributedString(
                    string: "• " + sentence + (i < sentences.count - 1 ? "\n\n" : ""),
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 17),
                        .foregroundColor: UIColor.black,
                        .paragraphStyle: paragraphStyle,
                    ]
                ))
        }
        infoLabel.attributedText = signatureRegisterGuideAttrString
        return infoLabel
    }()
    private(set) lazy var signatureRegisterCompletionGuideLabel: UILabel = {
        let infoLabel = UILabel()
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.numberOfLines = 0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.alignment = .left

        let sentences = [
            "Signature registration is complete.",
            "The visibility of the center point can be changed in Settings.",
            "The setting to hide drawn lines during signature authentication can be changed in Settings.",
            "The tolerance for signature authentication can be adjusted in Settings.",
        ]

        for (i, sentence) in sentences.enumerated() {
            signatureRegisterCompletionGuideAttrString.append(
                NSAttributedString(
                    string: "• " + sentence + (i < sentences.count - 1 ? "\n\n" : ""),
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 17),
                        .foregroundColor: UIColor.black,
                        .paragraphStyle: paragraphStyle,
                    ]
                ))
        }
        infoLabel.attributedText = signatureRegisterCompletionGuideAttrString
        return infoLabel
    }()
    private let signatureButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "signature")
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .systemBlue
        config.cornerStyle = .capsule
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 20)

        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private(set) var signView = SignatureDrawingView()

    private let signatureRegisterGuideAttrString = NSMutableAttributedString()
    private let signatureRegisterCompletionGuideAttrString = NSMutableAttributedString()

    private var isPresentSignatureHistory = false
    private var signatureHistories: [UIView] = []
    private var centerPoints: [UIImageView] = []
    private var currentSignatureHistoryIndex = 0
    var isRegistering: Bool = false

    private var nextSignatureHistorySwipe: UISwipeGestureRecognizer?
    private var previousSignatureHistorySwipe: UISwipeGestureRecognizer?

    var dispatcher: PassthroughSubject<MemoHomeViewInput, Never>? {
        didSet {
            signView.finishDrawing = { sign in
                self.dispatcher?
                    .send(
                        self.isRegistering ? .willRegisterSignature(sign) : .willTryToUnlockPrivateDirectoryAccess(sign)
                    )
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        isHidden = true
        isUserInteractionEnabled = true

        addSubview(privateDirectoryBlockCommentLabel)
        addSubview(signView)
        addSubview(signatureRegisterGuideLabel)
        addSubview(signatureRegisterCompletionGuideLabel)
        addSubview(getStartButton)
        addSubview(finishButton)
        addSubview(unregisterButton)
        addSubview(DoneButton)
        addSubview(alertLabel)

        signatureButton.addSubview(badgeLabel)
        addSubview(signatureButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            privateDirectoryBlockCommentLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            privateDirectoryBlockCommentLabel.topAnchor
                .constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 40),

            signatureRegisterGuideLabel.topAnchor.constraint(
                equalTo: privateDirectoryBlockCommentLabel.bottomAnchor, constant: 30),
            signatureRegisterGuideLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            signatureRegisterGuideLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            signatureRegisterCompletionGuideLabel.topAnchor.constraint(
                equalTo: privateDirectoryBlockCommentLabel.bottomAnchor, constant: 30),
            signatureRegisterCompletionGuideLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            signatureRegisterCompletionGuideLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            alertLabel.topAnchor.constraint(equalTo: privateDirectoryBlockCommentLabel.bottomAnchor, constant: 20),
            alertLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            alertLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            signView.topAnchor.constraint(equalTo: topAnchor),
            signView.leadingAnchor.constraint(equalTo: leadingAnchor),
            signView.trailingAnchor.constraint(equalTo: trailingAnchor),
            signView.bottomAnchor.constraint(equalTo: bottomAnchor),

            getStartButton.heightAnchor.constraint(equalToConstant: 60),
            getStartButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            getStartButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            getStartButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -60),

            DoneButton.heightAnchor.constraint(equalToConstant: 60),
            DoneButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            DoneButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            DoneButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -60),

            signatureButton.widthAnchor.constraint(equalToConstant: 60),
            signatureButton.heightAnchor.constraint(equalToConstant: 60),
            signatureButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -60),
            signatureButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),

            badgeLabel.widthAnchor.constraint(equalToConstant: 30),
            badgeLabel.heightAnchor.constraint(equalToConstant: 30),
            badgeLabel.topAnchor.constraint(equalTo: signatureButton.topAnchor, constant: -8),
            badgeLabel.trailingAnchor.constraint(equalTo: signatureButton.trailingAnchor, constant: 8),

            finishButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -60),
            finishButton.leadingAnchor.constraint(equalTo: signatureButton.trailingAnchor, constant: 20),
            finishButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            finishButton.heightAnchor.constraint(equalToConstant: 60),

            unregisterButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -60),
            unregisterButton.leadingAnchor.constraint(equalTo: signatureButton.trailingAnchor, constant: 20),
            unregisterButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            unregisterButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }

    private func setupActions() {
        getStartButton.addAction(UIAction { _ in self.readyToRegisterSignature() }, for: .touchUpInside)

        signatureButton.addAction(
            UIAction { _ in
                if self.isPresentSignatureHistory {
                    self.dismissSignatureSnapshotHistories()
                } else {
                    self.presnetSignatureSnapshotHistories()
                }
            }, for: .touchUpInside)

        unregisterButton.addAction(
            UIAction { [self] _ in
                dispatcher?.send(.willRemoveSignatureHistory(currentSignatureHistoryIndex))
                let r = signatureHistories.remove(at: currentSignatureHistoryIndex)
                let cp = centerPoints.remove(at: currentSignatureHistoryIndex)

                cp.removeFromSuperview()
                r.removeFromSuperview()

                badgeLabel.text = String(Int(badgeLabel.text!)! - 1)
                if signatureHistories.isEmpty {
                    privateDirectoryBlockCommentLabel.text = "Register Pass Signature"
                    signatureButton.configuration?.image = UIImage(systemName: "signature")

                    signView.isUserInteractionEnabled = true
                    finishButton.isHidden = false
                    unregisterButton.isHidden = true
                    isPresentSignatureHistory = false

                    nextSignatureHistorySwipe?.isEnabled = false
                    previousSignatureHistorySwipe?.isEnabled = false
                } else {
                    let ni = max(0, min(signatureHistories.count - 1, currentSignatureHistoryIndex))
                    currentSignatureHistoryIndex = ni
                    signatureHistories[ni].isHidden = false
                }
            }, for: .touchUpInside)

        finishButton.addAction(
            UIAction { _ in
                if self.signatureHistories.count < 8 {
                    self.needMoreRegister()
                } else {
                    self.dispatcher?.send(.willSuccessRegisterSignature)
                }
            }, for: .touchUpInside)

        DoneButton.addAction(
            UIAction { _ in self.readyToVerifySignature(centers: [], dopt: .shown) }, for: .touchUpInside)

        nextSignatureHistorySwipe =
            UISwipeGestureRecognizer(target: self, action: #selector(handleSignatureHistorySwipe(_:)))
        previousSignatureHistorySwipe =
            UISwipeGestureRecognizer(target: self, action: #selector(handleSignatureHistorySwipe(_:)))

        nextSignatureHistorySwipe?.direction = .left
        addGestureRecognizer(nextSignatureHistorySwipe!)

        previousSignatureHistorySwipe?.direction = .right
        addGestureRecognizer(previousSignatureHistorySwipe!)

        nextSignatureHistorySwipe?.isEnabled = false
        previousSignatureHistorySwipe?.isEnabled = false
    }

    func applyColor(_ colorManager: any AppAppearanceManagerType = AppAppearanceManager.shared) {
        privateDirectoryBlockCommentLabel.textColor = colorManager.appTintColor
        signatureRegisterGuideAttrString.enumerateAttributes(
            in: NSRange(location: 0, length: signatureRegisterGuideAttrString.length)
        ) {
            attrs, range, stop in
            signatureRegisterGuideAttrString.addAttribute(
                .foregroundColor, value: colorManager.appTintColor, range: range)
        }
        signatureRegisterGuideLabel.attributedText = signatureRegisterGuideAttrString

        signatureRegisterCompletionGuideAttrString.enumerateAttributes(
            in: NSRange(location: 0, length: signatureRegisterCompletionGuideAttrString.length)
        ) {
            attrs, range, stop in
            signatureRegisterCompletionGuideAttrString.addAttribute(
                .foregroundColor, value: colorManager.appTintColor, range: range)
        }
        signatureRegisterCompletionGuideLabel.attributedText = signatureRegisterCompletionGuideAttrString
    }

    func clear() { signView.clear() }

    func registerSignatureGuideView() {
        privateDirectoryBlockCommentLabel.text = "Register Pass Signature"
        signView.isUserInteractionEnabled = false
        nextSignatureHistorySwipe?.isEnabled = false
        previousSignatureHistorySwipe?.isEnabled = false
        isRegistering = true
        signatureRegisterGuideLabel.isHidden = false
        getStartButton.isHidden = false

        finishButton.isHidden = true
        signatureRegisterCompletionGuideLabel.isHidden = true
        signatureButton.isHidden = true
        DoneButton.isHidden = true
        unregisterButton.isHidden = true
        alertLabel.isHidden = true

        badgeLabel.text = "0"
        currentSignatureHistoryIndex = 0

        signatureHistories.forEach { $0.removeFromSuperview() }
        signatureHistories = []

        centerPoints.forEach { $0.removeFromSuperview() }
        centerPoints = []

        isPresentSignatureHistory = false
    }

    func registerSignatureCompleteView() {
        privateDirectoryBlockCommentLabel.text = "Register Complete"

        finishButton.isHidden = true
        signatureButton.isHidden = true
        DoneButton.isHidden = false
        signatureRegisterCompletionGuideLabel.isHidden = false
        alertLabel.isHidden = true
        signView.isUserInteractionEnabled = false
        centerPoints.forEach { $0.isHidden = true }

        nextSignatureHistorySwipe?.isEnabled = false
        previousSignatureHistorySwipe?.isEnabled = false
    }

    @objc private func handleSignatureHistorySwipe(_ gr: UISwipeGestureRecognizer) {
        nextSignatureHistorySwipe?.isEnabled = false
        previousSignatureHistorySwipe?.isEnabled = false

        let isLeft = gr.direction == .left
        let outX: CGFloat = isLeft ? -UIView.screenWidth : UIView.screenWidth

        let current = signatureHistories[currentSignatureHistoryIndex]

        if signatureHistories.count <= 1 {
            nextSignatureHistorySwipe?.isEnabled = true
            previousSignatureHistorySwipe?.isEnabled = true
            return
        }

        currentSignatureHistoryIndex += isLeft ? 1 : -1
        if currentSignatureHistoryIndex >= signatureHistories.count { currentSignatureHistoryIndex = 0 }
        if currentSignatureHistoryIndex < 0 { currentSignatureHistoryIndex = signatureHistories.count - 1 }

        let next = signatureHistories[currentSignatureHistoryIndex]
        next.transform = CGAffineTransform(translationX: -outX, y: 0)
        next.isHidden = false

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            current.transform = CGAffineTransform(translationX: outX, y: 0)
            next.transform = .identity
        } completion: { _ in
            current.isHidden = true
            current.transform = .identity
            self.nextSignatureHistorySwipe?.isEnabled = true
            self.previousSignatureHistorySwipe?.isEnabled = true
        }
    }

    func saveSnapshotHistory() {
        if let f = signView.signatureSnapshot.last {
            f.frame = CGRect(
                x: f.frame.origin.x, y: f.frame.origin.y,
                width: f.bounds.width, height: f.bounds.height)
            addSubview(f)
            signatureHistories.append(f)

            UIView.transition(with: f, duration: 0.5, options: [.transitionCurlDown, .allowAnimatedContent]) {
                let targetX = self.signatureButton.center.x - f.center.x
                let targetY = self.signatureButton.center.y - f.center.y

                f.transform = CGAffineTransform(translationX: targetX, y: targetY).scaledBy(x: 0.3, y: 0.3)
                f.alpha = 0.1
            } completion: { _ in
                f.isHidden = true
                f.alpha = 1
                f.transform = .identity
            }

            badgeLabel.text = String(Int(badgeLabel.text!)! + 1)
        }
    }

    func readyToVerifySignature(centers: [[Double]], dopt: DrawingDisplayOption) {
        UIView.performWithoutAnimation { [self] in
            subviews
                .compactMap { $0 as? UIImageView }
                .filter { $0.accessibilityIdentifier == "centerPoint" }
                .forEach { $0.removeFromSuperview() }

            for center in centers {
                let centerImageView = UIImageView(image: UIImage(systemName: "sparkles"))
                centerImageView.accessibilityIdentifier = "centerPoint"
                centerImageView.tintColor = .systemBlue
                centerImageView.frame = CGRect(x: center[0], y: center[1], width: 20, height: 20)
                centerPoints.append(centerImageView)
                addSubview(centerImageView)
            }

            privateDirectoryBlockCommentLabel.text = "Draw Pass Signature"
            signatureButton.isHidden = true
            finishButton.isHidden = true
            signatureRegisterGuideLabel.isHidden = true
            signatureRegisterCompletionGuideLabel.isHidden = true
            getStartButton.isHidden = true
            DoneButton.isHidden = true
            alertLabel.isHidden = true
            signView.isUserInteractionEnabled = true
            isRegistering = false
            centerPoints.forEach { $0.isHidden = false }
            signView.isVerifing = true
            switch dopt {
                case .shown:
                    signView.isTailEffect = false

                case .partial:
                    signView.isTailEffect = true
                    signView.tailLength = 12

                case .hidden:
                    signView.isTailEffect = true
                    signView.tailLength = 1
            }
        }
    }

    func addCenterPoint(center: [Double]) {
        let centerImageView = UIImageView(image: UIImage(systemName: "sparkles"))
        centerImageView.tintColor = .systemBlue
        centerImageView.frame = CGRect(x: center[0], y: center[1], width: 20, height: 20)
        centerPoints.append(centerImageView)
        addSubview(centerImageView)
    }

    func fail() {
        alertLabel.text = "signature pattern does not match, or the position or size is different."
        alertLabel.isHidden = false
    }

    func needMoreRegister() {
        alertLabel.text = "Need to register more signatures."
        alertLabel.isHidden = false
    }

    private func readyToRegisterSignature() {
        signatureRegisterGuideLabel.isHidden = true
        signatureRegisterCompletionGuideLabel.isHidden = true
        getStartButton.isHidden = true
        signatureButton.isHidden = false
        finishButton.isHidden = false
        badgeLabel.text = "0"

        signView.isUserInteractionEnabled = true

        nextSignatureHistorySwipe?.isEnabled = false
        previousSignatureHistorySwipe?.isEnabled = false
        signView.isVerifing = false
    }

    private func presnetSignatureSnapshotHistories() {
        if !signatureHistories.isEmpty {
            privateDirectoryBlockCommentLabel.text = "Signature History"
            signatureButton.configuration?.image = UIImage(systemName: "lasso.badge.sparkles")
            signView.isUserInteractionEnabled = false
            signatureHistories[currentSignatureHistoryIndex].isHidden = false
            finishButton.isHidden = true
            alertLabel.isHidden = true
            unregisterButton.isHidden = false
            isPresentSignatureHistory = true
            centerPoints.forEach { $0.isHidden = true }

            nextSignatureHistorySwipe?.isEnabled = true
            previousSignatureHistorySwipe?.isEnabled = true
        }
    }

    private func dismissSignatureSnapshotHistories() {
        if !signatureHistories.isEmpty {
            privateDirectoryBlockCommentLabel.text = "Register Pass Signature"
            signatureButton.configuration?.image = UIImage(systemName: "signature")
            signView.isUserInteractionEnabled = true
            signatureHistories[currentSignatureHistoryIndex].isHidden = true
            finishButton.isHidden = false
            unregisterButton.isHidden = true
            isPresentSignatureHistory = false
            centerPoints.forEach { $0.isHidden = false }

            nextSignatureHistorySwipe?.isEnabled = false
            previousSignatureHistorySwipe?.isEnabled = false
        }
    }
}
