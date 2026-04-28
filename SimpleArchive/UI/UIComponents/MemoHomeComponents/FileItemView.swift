import Combine
import Foundation
import UIKit

final class FileItemView: UICollectionViewCell, UITextFieldDelegate {
    private(set) lazy var containerView: UIView = {
        $0.layer.cornerRadius = 15
        $0.isUserInteractionEnabled = true
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIView())
    private(set) lazy var fileIconImageView: UIImageView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.contentMode = .scaleAspectFit
        return $0
    }(UIImageView())
    private(set) lazy var titleLabel: UILabel = {
        $0.font = .systemFont(ofSize: 17)
        $0.numberOfLines = 1
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.7
        $0.textAlignment = .center
        $0.isUserInteractionEnabled = true
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UILabel())
    private(set) lazy var hideButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "eye.slash")
        config.imageColorTransformer = .init { _ in .white }
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 15)

        config.baseForegroundColor = .white
        config.baseBackgroundColor = .systemTeal
        config.cornerStyle = .capsule

        let button = UIButton(configuration: config)
        button.isHidden = true
        button.alpha = 0
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private(set) lazy var removeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "trash")
        config.imageColorTransformer = .init { _ in .white }
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 15)

        config.imagePadding = 8
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .systemRed
        config.cornerStyle = .capsule

        let button = UIButton(configuration: config)
        button.isHidden = true
        button.alpha = 0
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private(set) lazy var moveButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "arrow.forward.folder")
        config.imageColorTransformer = .init { _ in .white }
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 19)

        var titleAttr = AttributedString("Move")
        titleAttr.font = .systemFont(ofSize: 18)
        config.attributedTitle = titleAttr

        config.imagePadding = 10
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .systemBlue
        config.cornerStyle = .large

        let button = UIButton(configuration: config)
        button.isHidden = true
        button.alpha = 0
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private(set) lazy var doneButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "checkmark.circle")
        config.imageColorTransformer = .init { _ in .white }
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 19)

        var titleAttr = AttributedString("Done")
        titleAttr.font = .systemFont(ofSize: 18)
        config.attributedTitle = titleAttr

        config.imagePadding = 10
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .systemGreen
        config.cornerStyle = .large

        let button = UIButton(configuration: config)
        button.isHidden = true
        button.alpha = 0
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: -===================== Item Information Labels =====================-

    private(set) lazy var fileInformationStackView: UIStackView = {
        let fileInformationStackView = UIStackView()
        fileInformationStackView.axis = .vertical
        fileInformationStackView.spacing = 8
        fileInformationStackView.alignment = .leading
        fileInformationStackView.isLayoutMarginsRelativeArrangement = true
        fileInformationStackView.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        fileInformationStackView.translatesAutoresizingMaskIntoConstraints = false
        return fileInformationStackView
    }()
    private(set) lazy var fileInformationScrollView: UIScrollView = {
        let fileInformationScrollView = UIScrollView()
        fileInformationScrollView.alwaysBounceVertical = true
        fileInformationScrollView.showsVerticalScrollIndicator = false
        fileInformationScrollView.showsHorizontalScrollIndicator = false
        fileInformationScrollView.translatesAutoresizingMaskIntoConstraints = false
        fileInformationScrollView.isHidden = true
        return fileInformationScrollView
    }()
    private(set) lazy var filePathLabel: UILabel = {
        let filePathLabel = UILabel()
        filePathLabel.numberOfLines = 0
        filePathLabel.isHidden = true
        filePathLabel.alpha = 0
        filePathLabel.lineBreakMode = .byWordWrapping
        filePathLabel.translatesAutoresizingMaskIntoConstraints = false
        return filePathLabel
    }()
    private(set) lazy var creationDateLabel: UILabel = {
        let creationDateLabel = UILabel()
        creationDateLabel.numberOfLines = 3
        creationDateLabel.isHidden = true
        creationDateLabel.alpha = 0
        return creationDateLabel
    }()
    private(set) lazy var itemSizeLabel: UILabel = {
        let itemSizeLabel = UILabel()
        itemSizeLabel.numberOfLines = 3
        itemSizeLabel.isHidden = true
        itemSizeLabel.alpha = 0
        return itemSizeLabel
    }()
    private(set) lazy var totalAudioCountLabel: UILabel = {
        let totalAudioCountLabel = UILabel()
        totalAudioCountLabel.numberOfLines = 3
        totalAudioCountLabel.isHidden = true
        totalAudioCountLabel.alpha = 0
        return totalAudioCountLabel
    }()
    private(set) lazy var columnsLabel: UILabel = {
        let columnsLabel = UILabel()
        columnsLabel.numberOfLines = 0
        columnsLabel.isHidden = true
        columnsLabel.alpha = 0
        columnsLabel.lineBreakMode = .byWordWrapping
        columnsLabel.translatesAutoresizingMaskIntoConstraints = false
        return columnsLabel
    }()
    private(set) lazy var rowCountLabel: UILabel = {
        let rowCountLabel = UILabel()
        rowCountLabel.numberOfLines = 3
        rowCountLabel.isHidden = true
        rowCountLabel.alpha = 0
        return rowCountLabel
    }()
    private(set) lazy var mostRecentSnapshotDateLabel: UILabel = {
        let mostRecentSnapshotDateLabel = UILabel()
        mostRecentSnapshotDateLabel.numberOfLines = 3
        mostRecentSnapshotDateLabel.isHidden = true
        mostRecentSnapshotDateLabel.alpha = 0
        return mostRecentSnapshotDateLabel
    }()
    private(set) lazy var totalAudioDurationLabel: UILabel = {
        let totalAudioDurationLabel = UILabel()
        totalAudioDurationLabel.numberOfLines = 3
        totalAudioDurationLabel.isHidden = true
        totalAudioDurationLabel.alpha = 0
        return totalAudioDurationLabel
    }()
    private(set) lazy var totalDirectoryCountLabel: UILabel = {
        let totalDirectoryCountLabel = UILabel()
        totalDirectoryCountLabel.numberOfLines = 3
        totalDirectoryCountLabel.isHidden = true
        totalDirectoryCountLabel.alpha = 0
        return totalDirectoryCountLabel
    }()
    private(set) lazy var totalPageCountLabel: UILabel = {
        let totalPageCountLabel = UILabel()
        totalPageCountLabel.numberOfLines = 3
        totalPageCountLabel.isHidden = true
        totalPageCountLabel.alpha = 0
        return totalPageCountLabel
    }()
    private(set) lazy var totalTextCountLabel: UILabel = {
        let totalTextComponentCountLabel = UILabel()
        totalTextComponentCountLabel.numberOfLines = 3
        totalTextComponentCountLabel.isHidden = true
        totalTextComponentCountLabel.alpha = 0
        return totalTextComponentCountLabel
    }()
    private(set) lazy var textComponentSummaryLabel: UILabel = {
        let textComponentSummaryLabel = UILabel()
        textComponentSummaryLabel.numberOfLines = 0
        textComponentSummaryLabel.isHidden = true
        textComponentSummaryLabel.alpha = 0
        textComponentSummaryLabel.lineBreakMode = .byWordWrapping
        textComponentSummaryLabel.translatesAutoresizingMaskIntoConstraints = false
        return textComponentSummaryLabel
    }()
    private(set) lazy var totalTableComponentCountLabel: UILabel = {
        let totalTableComponentCountLabel = UILabel()
        totalTableComponentCountLabel.numberOfLines = 3
        totalTableComponentCountLabel.isHidden = true
        totalTableComponentCountLabel.alpha = 0
        return totalTableComponentCountLabel
    }()
    private(set) lazy var totalAudioComponentCountLabel: UILabel = {
        let totalAudioComponentCountLabel = UILabel()
        totalAudioComponentCountLabel.numberOfLines = 3
        totalAudioComponentCountLabel.isHidden = true
        totalAudioComponentCountLabel.alpha = 0
        return totalAudioComponentCountLabel
    }()

    // MARK: -================== Item Information Labels END ==================-

    private(set) lazy var fileItemTitleTextField: UITextField = {
        let fileItemTitleTextField = UITextField()
        fileItemTitleTextField.font = .systemFont(ofSize: 23, weight: .semibold)
        fileItemTitleTextField.returnKeyType = .done
        fileItemTitleTextField.isHidden = true
        fileItemTitleTextField.textAlignment = .center
        fileItemTitleTextField.translatesAutoresizingMaskIntoConstraints = false
        return fileItemTitleTextField
    }()
    private(set) lazy var lineView: UIView = {
        let lineView = UIView()
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.backgroundColor = .systemGray4
        lineView.isHidden = true
        lineView.alpha = 0
        lineView.layer.cornerRadius = 1.5
        return lineView
    }()
    private(set) lazy var colorsView: UIView = {
        let colorStackView = UIView()
        colorStackView.isHidden = true
        colorStackView.alpha = 0
        colorStackView.translatesAutoresizingMaskIntoConstraints = false
        return colorStackView
    }()
    private(set) lazy var colorCircles: [UIView] = FileItemColor.allCases.map {
        let v = UIView()
        v.backgroundColor = $0.color.bg
        v.layer.cornerRadius = 15
        v.alpha = 0
        v.isHidden = true
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.2
        v.layer.shadowOffset = .init(width: 0, height: 1)
        v.isUserInteractionEnabled = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }
    private(set) lazy var blockView: UIView = {
        let blockView = UIView()
        blockView.translatesAutoresizingMaskIntoConstraints = false
        blockView.backgroundColor = .clear
        blockView.isUserInteractionEnabled = true
        blockView.alpha = 1
        return blockView
    }()

    private lazy var panGesture: UIPanGestureRecognizer = {
        let gr = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        gr.delegate = self
        return gr
    }()
    private(set) var longTapGesture = UILongPressGestureRecognizer()

    static let reuseIdentifier = "FileItemView"
    static var z: CGFloat = 2
    private var scaledBeganPoint: CGPoint?
    private var beganPointInWindow: CGPoint?
    private var itemID: UUID?
    private var dispatcher: PassthroughSubject<MemoHomeViewInput, Never>?
    private let innerShadowLayer = CAShapeLayer()
    private let cornerRadius: CGFloat = 15
    private let colorSetSpacing: Double = 15
    private let colorSetCount = Double(FileItemColor.allCases.count)
    private let infoContentsTextAnimateStep = 24
    private lazy var colorViewWidth = Double(30 * colorSetCount) + (colorSetSpacing * Double(colorSetCount + 1))
    private let infoLabelDivisionDottedLineFont = UIFont.systemFont(ofSize: 21, weight: .bold)
    private lazy var dottedLineWidth = "⎺".size(withAttributes: [.font: infoLabelDivisionDottedLineFont]).width
    private lazy var infoLabelDivisionDottedLine =
        "\n" + String(repeating: "⎺", count: Int((UIView.screenWidth * pow(0.8, 2) / dottedLineWidth)))

    private var originZ: CGFloat!
    private var originPoint: CGPoint!
    private var originFrame: CGSize!
    private var scaleX: Double!
    private var scaleY: Double!
    private weak var collectionViewRef: UICollectionView?
    private let duration: Double = 0.6
    private var fileItemColor: FileItemColor = .white

    private var originBlockPoint: CGPoint!
    private var itemInformationVCPresentAnimator: UIViewPropertyAnimator?
    private var timingParameterPoint = CGPoint(x: 0.2, y: 0.7)
    private var timingParameterPoint2 = CGPoint(x: 0.01, y: 1.0)
    private lazy var timing = UICubicTimingParameters(
        controlPoint1: timingParameterPoint, controlPoint2: timingParameterPoint2)

    private var colorCircleSubscriptions = Set<AnyCancellable>()

    private var fileIconDefaultConstraints: [NSLayoutConstraint] = []
    private var fileIconBarConstraints: [NSLayoutConstraint] = []
    private var fileIconInfoConstraints: [NSLayoutConstraint] = []

    private var titleLabelDefaultConstraints: [NSLayoutConstraint] = []
    private var titleLabelBarConstraints: [NSLayoutConstraint] = []
    private var titleLabelInfoConstraints: [NSLayoutConstraint] = []

    private var hideButtonDefaultConstraints: [NSLayoutConstraint] = []
    private var hideButtonInfoConstraints: [NSLayoutConstraint] = []

    private var removeButtonDefaultConstraints: [NSLayoutConstraint] = []
    private var removeButtonInfoConstraints: [NSLayoutConstraint] = []

    private var moveButtonDefaultConstraints: [NSLayoutConstraint] = []
    private var moveButtonInfoConstraints: [NSLayoutConstraint] = []

    private var doneButtonDefaultConstraints: [NSLayoutConstraint] = []
    private var doneButtonInfoConstraints: [NSLayoutConstraint] = []

    private var colorStackViewDefaultConstraints: [NSLayoutConstraint] = []
    private var colorStackViewInfoConstraints: [NSLayoutConstraint] = []

    private var fileInformationScrollViewDefaultConstraints: [NSLayoutConstraint] = []
    private var fileInformationScrollViewInfoConstraints: [NSLayoutConstraint] = []

    private var lineViewWidthConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        titleLabel.text = ""
        itemID = nil
        panGesture.isEnabled = true
    }

    // MARK: -===================== set up =====================-

    private func setupUI() {
        clipsToBounds = true
        contentView.addSubview(containerView)
        contentView.backgroundColor = .clear
        contentView.layer.cornerRadius = cornerRadius
        backgroundColor = .clear

        containerView.addSubview(fileIconImageView)
        containerView.addSubview(titleLabel)

        fileInformationScrollView.addSubview(fileInformationStackView)

        layer.cornerRadius = cornerRadius

        containerView.addSubview(removeButton)
        containerView.addSubview(doneButton)
        containerView.addSubview(moveButton)
        containerView.addSubview(hideButton)
        containerView.addSubview(lineView)
        containerView.addSubview(fileItemTitleTextField)

        fileInformationStackView.addArrangedSubview(filePathLabel)
        fileInformationStackView.addArrangedSubview(creationDateLabel)
        fileInformationStackView.addArrangedSubview(itemSizeLabel)
        fileInformationStackView.addArrangedSubview(mostRecentSnapshotDateLabel)
        fileInformationStackView.addArrangedSubview(columnsLabel)
        fileInformationStackView.addArrangedSubview(rowCountLabel)
        fileInformationStackView.addArrangedSubview(textComponentSummaryLabel)
        fileInformationStackView.addArrangedSubview(totalDirectoryCountLabel)
        fileInformationStackView.addArrangedSubview(totalPageCountLabel)
        fileInformationStackView.addArrangedSubview(totalAudioCountLabel)
        fileInformationStackView.addArrangedSubview(totalAudioDurationLabel)
        fileInformationStackView.addArrangedSubview(totalTextCountLabel)
        fileInformationStackView.addArrangedSubview(totalTableComponentCountLabel)
        fileInformationStackView.addArrangedSubview(totalAudioComponentCountLabel)

        containerView.addSubview(fileInformationScrollView)
        fileItemTitleTextField.delegate = self

        colorCircles.forEach { colorsView.addSubview($0) }
        containerView.addSubview(colorsView)
    }

    private func setupConstraints() {
        fileIconDefaultConstraints = [
            fileIconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            fileIconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            fileIconImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            fileIconImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -40),
        ]

        fileIconInfoConstraints = [
            fileIconImageView.widthAnchor.constraint(equalToConstant: 100),
            fileIconImageView.heightAnchor.constraint(equalToConstant: 100),
            fileIconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            fileIconImageView.topAnchor.constraint(equalTo: removeButton.bottomAnchor, constant: 5),
        ]

        fileIconBarConstraints = [
            fileIconImageView.widthAnchor.constraint(equalToConstant: 50),
            fileIconImageView.heightAnchor.constraint(equalToConstant: 50),
            fileIconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            fileIconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
        ]

        titleLabelDefaultConstraints = [
            titleLabel.topAnchor.constraint(equalTo: fileIconImageView.bottomAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            titleLabel.widthAnchor.constraint(lessThanOrEqualTo: containerView.widthAnchor, multiplier: 0.8),
        ]

        titleLabelInfoConstraints = [
            titleLabel.widthAnchor.constraint(lessThanOrEqualTo: containerView.widthAnchor, multiplier: 0.8),
            titleLabel.heightAnchor.constraint(equalToConstant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: fileIconImageView.bottomAnchor),
        ]

        titleLabelBarConstraints = [
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 5),
            titleLabel.leadingAnchor.constraint(equalTo: fileIconImageView.trailingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -5),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -5),
        ]

        removeButtonDefaultConstraints = [
            removeButton.widthAnchor.constraint(equalToConstant: 0),
            removeButton.heightAnchor.constraint(equalToConstant: 0),
            removeButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            removeButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ]

        removeButtonInfoConstraints = [
            removeButton.widthAnchor.constraint(equalToConstant: 40),
            removeButton.heightAnchor.constraint(equalToConstant: 40),
            removeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),
            removeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
        ]

        hideButtonDefaultConstraints = [
            hideButton.widthAnchor.constraint(equalToConstant: 0),
            hideButton.heightAnchor.constraint(equalToConstant: 0),
            hideButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            hideButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ]

        hideButtonInfoConstraints = [
            hideButton.widthAnchor.constraint(equalToConstant: 40),
            hideButton.heightAnchor.constraint(equalToConstant: 40),
            hideButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),
            hideButton.leadingAnchor.constraint(equalTo: removeButton.trailingAnchor, constant: 10),
        ]

        moveButtonDefaultConstraints = [
            moveButton.widthAnchor.constraint(equalToConstant: 0),
            moveButton.heightAnchor.constraint(equalToConstant: 0),
            moveButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            moveButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ]

        moveButtonInfoConstraints = [
            moveButton.widthAnchor.constraint(equalToConstant: (UIView.screenWidth * 0.8 - 45) * 0.5),
            moveButton.heightAnchor.constraint(equalToConstant: 50),
            moveButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
            moveButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -15),
        ]

        doneButtonDefaultConstraints = [
            doneButton.widthAnchor.constraint(equalToConstant: 0),
            doneButton.heightAnchor.constraint(equalToConstant: 0),
            doneButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            doneButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ]

        doneButtonInfoConstraints = [
            doneButton.widthAnchor.constraint(equalToConstant: (UIView.screenWidth * 0.8 - 45) * 0.5),
            doneButton.heightAnchor.constraint(equalToConstant: 50),
            doneButton.leadingAnchor.constraint(equalTo: moveButton.trailingAnchor, constant: 15),
            doneButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -15),
        ]

        lineViewWidthConstraint = lineView.widthAnchor.constraint(equalToConstant: 1)

        colorStackViewDefaultConstraints = [
            colorsView.widthAnchor.constraint(equalToConstant: containerView.frame.width * 0.8),
            colorsView.heightAnchor.constraint(equalToConstant: 0),
            colorsView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            colorsView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ]

        colorStackViewInfoConstraints = [
            colorsView.topAnchor.constraint(equalTo: lineView.bottomAnchor),
            colorsView.heightAnchor.constraint(equalToConstant: 40),
            colorsView.widthAnchor.constraint(equalToConstant: colorViewWidth),
            colorsView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        ]

        colorCircles.enumerated()
            .forEach { i, v in
                v.widthAnchor.constraint(equalToConstant: 30).isActive = true
                v.heightAnchor.constraint(equalToConstant: 30).isActive = true
                v.topAnchor.constraint(equalTo: colorsView.topAnchor, constant: 10).isActive = true
                v.leadingAnchor
                    .constraint(
                        equalTo: colorsView.leadingAnchor,
                        constant: Double(i * 30) + (colorSetSpacing * Double(i + 1))
                    )
                    .isActive = true
            }

        fileInformationScrollViewDefaultConstraints = [
            fileInformationScrollView.widthAnchor.constraint(equalToConstant: 0),
            fileInformationScrollView.heightAnchor.constraint(equalToConstant: 0),
            fileInformationScrollView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            fileInformationScrollView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ]

        fileInformationScrollViewInfoConstraints = [
            fileInformationScrollView.topAnchor.constraint(equalTo: colorsView.bottomAnchor, constant: 10),
            fileInformationScrollView.widthAnchor.constraint(equalToConstant: (UIView.screenWidth * 0.8) * 0.8),
            fileInformationScrollView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            fileInformationScrollView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -20),
        ]

        NSLayoutConstraint.activate(
            [
                containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
                containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ] + titleLabelDefaultConstraints
                + fileIconDefaultConstraints
                + hideButtonDefaultConstraints
                + removeButtonDefaultConstraints
                + moveButtonDefaultConstraints
                + doneButtonDefaultConstraints
                + colorStackViewDefaultConstraints
        )

        NSLayoutConstraint.activate(
            fileInformationScrollViewDefaultConstraints + [
                fileInformationStackView.topAnchor.constraint(equalTo: fileInformationScrollView.topAnchor),
                fileInformationStackView.leadingAnchor.constraint(equalTo: fileInformationScrollView.leadingAnchor),
                fileInformationStackView.trailingAnchor.constraint(equalTo: fileInformationScrollView.trailingAnchor),
                fileInformationStackView.bottomAnchor.constraint(equalTo: fileInformationScrollView.bottomAnchor),

                fileItemTitleTextField.widthAnchor.constraint(equalToConstant: UIView.screenWidth * 0.8 * 0.8),
                fileItemTitleTextField.heightAnchor.constraint(equalToConstant: 30),
                fileItemTitleTextField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                fileItemTitleTextField.topAnchor.constraint(equalTo: fileIconImageView.bottomAnchor),

                lineViewWidthConstraint!,
                lineView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
                lineView.heightAnchor.constraint(equalToConstant: 3),
                lineView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -30),

                textComponentSummaryLabel.widthAnchor.constraint(equalTo: fileInformationScrollView.widthAnchor),
                filePathLabel.widthAnchor.constraint(equalTo: fileInformationScrollView.widthAnchor),
                columnsLabel.widthAnchor.constraint(equalTo: fileInformationScrollView.widthAnchor),
            ]
        )
    }

    private func setupGestures() {
        contentView.addGestureRecognizer(longTapGesture)
        contentView.addGestureRecognizer(panGesture)

        longTapGesture.minimumPressDuration = 0.3
        longTapGesture.allowableMovement = 20
        longTapGesture.addTarget(self, action: #selector(longTapGestureHandler))

        contentView.addGestureRecognizer(panGesture)
        panGesture.isEnabled = true

        removeButton.addAction(
            UIAction { _ in
                self.setOriginAnimator {
                    self.dispatcher?.send(.willMoveFileToDormantBox(self.itemID!))
                }
            }, for: .touchUpInside)

        doneButton.addAction(UIAction { _ in self.setOriginAnimator() }, for: .touchUpInside)

        colorCircles.enumerated()
            .forEach { i, circle in
                circle.throttleUIViewTapGesturePublisher()
                    .sink { _ in
                        UIView.animate(withDuration: 0.3) {
                            let color = FileItemColor.allCases[i]
                            self.fileItemColor = color
                            self.containerView.backgroundColor = color.color.bg?.withAlphaComponent(0.5)
                            self.titleLabel.textColor = color.color.title
                            self.fileItemTitleTextField.textColor = color.color.title
                            self.setInnerShadowColor()
                            self.dispatcher?.send(.willChangeFileItemColor(self.itemID!, color))
                        }
                    }
                    .store(in: &colorCircleSubscriptions)
            }
    }

    private func setFileItemSizeState() {
        let sizes: [UIConstants.ItemSize] = [.small, .medium, .large, .bar]
        var diss: [Double] = []
        for size in sizes {
            let wdis = abs(frame.size.width - size.size.width)
            let hdis = abs(frame.size.height - size.size.height)
            diss.append(wdis + hdis)
        }
        let index = diss.indices.min(by: { diss[$0] < diss[$1] })

        UIView.animate(withDuration: 0.2) { [self] in
            if index == 0 {
                layer.borderColor = UIColor.green.cgColor
            } else if index == 1 {
                layer.borderColor = UIColor.orange.cgColor
            } else if index == 2 {
                layer.borderColor = UIColor.red.cgColor
            } else {
                layer.borderColor = UIColor.blue.cgColor
            }

            if index == 0 {
                titleLabel.numberOfLines = 1
            } else {
                titleLabel.numberOfLines = 2
            }

            if index == 3 {
                fileIconDefaultConstraints.forEach { $0.isActive = false }
                titleLabelDefaultConstraints.forEach { $0.isActive = false }

                fileIconBarConstraints.forEach { $0.isActive = true }
                titleLabelBarConstraints.forEach { $0.isActive = true }
            } else {
                fileIconBarConstraints.forEach { $0.isActive = false }
                titleLabelBarConstraints.forEach { $0.isActive = false }

                fileIconDefaultConstraints.forEach { $0.isActive = true }
                titleLabelDefaultConstraints.forEach { $0.isActive = true }
            }
            layoutIfNeeded()
        }
    }

    // MARK: -===================== Inner Shadow Configure =====================-

    override func layoutSubviews() {
        super.layoutSubviews()
        if removeButton.isHidden {
            innerShadowLayer.frame = bounds
            let path = UIBezierPath(roundedRect: bounds.insetBy(dx: -9, dy: -9), cornerRadius: cornerRadius)
            let cutout = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).reversing()
            path.append(cutout)

            innerShadowLayer.shadowPath = path.cgPath
            setInnerShadowColor()
            innerShadowLayer.shadowOffset = .init(width: -3, height: 3)
            setFileItemSizeState()
            layoutIfNeeded()
        }
    }

    private func setInnerShadowColor() {
        if fileItemColor == .white {
            innerShadowLayer.shadowColor = UIColor.gray.cgColor
            innerShadowLayer.shadowOpacity = 0.15
            innerShadowLayer.shadowRadius = 6
        } else {
            innerShadowLayer.shadowColor = UIColor.gray.cgColor
            innerShadowLayer.shadowOpacity = 0.07
            innerShadowLayer.shadowRadius = 3
        }
    }

    private func setInnerShadowLayer() {
        innerShadowLayer.frame = bounds
        containerView.layer.addSublayer(innerShadowLayer)

        let path = UIBezierPath(roundedRect: bounds.insetBy(dx: -9, dy: -9), cornerRadius: cornerRadius)
        let cutout = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).reversing()
        path.append(cutout)

        innerShadowLayer.cornerRadius = cornerRadius
        innerShadowLayer.shadowPath = path.cgPath
        innerShadowLayer.masksToBounds = true
        setInnerShadowColor()
        innerShadowLayer.shadowOffset = .init(width: -3, height: 3)
        innerShadowLayer.fillRule = .evenOdd
    }

    // MARK: -===================== Information View Presentation Animation =====================-

    private func setAnimator() {
        let animator = UIViewPropertyAnimator(duration: duration * 1.5, timingParameters: timing)
        dispatcher?.send(.willPresentFileItemInfoView(itemID!))

        [moveButton, doneButton, hideButton, removeButton].forEach { $0.isUserInteractionEnabled = false }

        containerView.isUserInteractionEnabled = false
        originZ = layer.zPosition
        originPoint = frame.origin
        originFrame = frame.size

        isHidden = true

        if let parentViewController, let window,
            let blurredImage = parentViewController.view.window?.fullSnapshotImage()?.blurredByPixcelSize(radius: 20)
        {
            isHidden = false

            let imageView = UIImageView(image: blurredImage)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.alpha = 0

            blockView.addSubview(imageView)
            blockView.sendSubviewToBack(imageView)

            window.addSubview(blockView)
            window.bringSubviewToFront(blockView)

            NSLayoutConstraint.activate([
                blockView.topAnchor.constraint(equalTo: window.topAnchor),
                blockView.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                blockView.trailingAnchor.constraint(equalTo: window.trailingAnchor),
                blockView.bottomAnchor.constraint(equalTo: window.bottomAnchor),

                imageView.topAnchor.constraint(equalTo: blockView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: blockView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: blockView.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: blockView.bottomAnchor),
            ])

            let views: [UIView] =
                [hideButton, removeButton, moveButton, doneButton, lineView, colorsView] + colorCircles
                + [fileInformationScrollView, filePathLabel, creationDateLabel, itemSizeLabel]

            views.forEach { $0.isHidden = false }

            collectionView?.allowsSelection = false
            collectionViewRef = collectionView

            let boundToBlockView = convert(bounds, to: blockView)
            originBlockPoint = boundToBlockView.origin
            blockView.addSubview(self)
            frame = boundToBlockView
        }

        animator.addAnimations { [self] in
            containerView.backgroundColor = containerView.backgroundColor?.withAlphaComponent(0.5)

            fileIconBarConstraints.forEach { $0.isActive = false }
            fileIconDefaultConstraints.forEach { $0.isActive = false }

            titleLabelBarConstraints.forEach { $0.isActive = false }
            titleLabelDefaultConstraints.forEach { $0.isActive = false }

            hideButtonDefaultConstraints.forEach { $0.isActive = false }
            removeButtonDefaultConstraints.forEach { $0.isActive = false }
            moveButtonDefaultConstraints.forEach { $0.isActive = false }
            doneButtonDefaultConstraints.forEach { $0.isActive = false }
            fileInformationScrollViewDefaultConstraints.forEach { $0.isActive = false }

            fileIconInfoConstraints.forEach { $0.isActive = true }
            titleLabelInfoConstraints.forEach { $0.isActive = true }

            hideButtonInfoConstraints.forEach { $0.isActive = true }
            removeButtonInfoConstraints.forEach { $0.isActive = true }
            moveButtonInfoConstraints.forEach { $0.isActive = true }
            doneButtonInfoConstraints.forEach { $0.isActive = true }

            scaleX = (UIView.screenWidth * 0.8) / frame.size.width
            scaleY = (UIView.screenHeight * 0.6) / frame.size.height

            frame.size = .init(width: frame.width * scaleX, height: frame.height * scaleY)
            frame.origin = .init(x: UIView.screenWidth * 0.1, y: 220)
            layer.zPosition = 999

            fileInformationScrollViewInfoConstraints.forEach { $0.isActive = true }

            hideButton.alpha = 1
            removeButton.alpha = 1
            moveButton.alpha = 1
            doneButton.alpha = 1
            fileInformationScrollView.alpha = 1

            titleLabel.font = .systemFont(ofSize: 23, weight: .semibold)
            layoutIfNeeded()
        }

        animator.addAnimations { [self] in
            CATransaction.begin()
            CATransaction.setAnimationDuration(duration)
            CATransaction.setAnimationTimingFunction(
                CAMediaTimingFunction(
                    controlPoints: Float(timingParameterPoint.x), Float(timingParameterPoint.y),
                    Float(timingParameterPoint2.x), Float(timingParameterPoint2.y)
                )
            )

            innerShadowLayer.frame.size.width = innerShadowLayer.frame.size.width * scaleX
            innerShadowLayer.frame.size.height = innerShadowLayer.frame.size.height * scaleY

            let path = UIBezierPath(
                roundedRect: innerShadowLayer.frame.insetBy(dx: -13, dy: -13), cornerRadius: cornerRadius)
            let cutout = UIBezierPath(roundedRect: innerShadowLayer.frame, cornerRadius: cornerRadius).reversing()
            path.append(cutout)

            let ba = CABasicAnimation(keyPath: "shadowPath")
            ba.fromValue = innerShadowLayer.shadowPath
            ba.toValue = path.cgPath

            let ba2 = CABasicAnimation(keyPath: "shadowOffset")
            ba2.fromValue = innerShadowLayer.shadowOffset
            ba2.toValue = CGSize(width: -2.6, height: 2.6)

            let g = CAAnimationGroup()
            g.animations = [ba, ba2]
            innerShadowLayer.add(g, forKey: nil)

            innerShadowLayer.cornerRadius = cornerRadius
            innerShadowLayer.shadowPath = path.cgPath
            innerShadowLayer.shadowOffset = .init(width: -2.6, height: 2.6)
            innerShadowLayer.shadowOpacity = 0.12
            innerShadowLayer.shadowRadius = 10

            CATransaction.commit()
        }

        itemInformationVCPresentAnimator = animator
        animator.startAnimation()

        UIView.animate(withDuration: duration * 0.5, delay: 0, options: .curveLinear) { [self] in
            blockView.subviews.compactMap { $0 as? UIImageView }.first?.alpha = 1
        }

        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear) { [self] in
            colorStackViewDefaultConstraints.forEach { $0.isActive = false }
            colorStackViewInfoConstraints.forEach { $0.isActive = true }
        }

        UIView.animateKeyframes(withDuration: duration * 1.5, delay: 0.2, options: .calculationModeLinear) { [self] in
            for i in 0..<Int(colorSetCount) {
                let di = Double(i)
                UIView.addKeyframe(
                    withRelativeStartTime: di / colorSetCount, relativeDuration: 1 / colorSetCount
                ) { [self] in
                    lineViewWidthConstraint.constant = (UIView.screenWidth * 0.8 - 60.0) / colorSetCount * (di + 1)
                    lineView.alpha = 0.1 + (0.9 / colorSetCount) * (di + 1)
                    colorsView.alpha = 0.4 + (0.6 / colorSetCount) * (di + 1)
                    for ii in 0...i { colorCircles[ii].alpha = 0.2 + (0.8 / colorSetCount) * (di + 1) }
                    layoutIfNeeded()
                }
            }
        } completion: { [self] _ in
            containerView.isUserInteractionEnabled = true
            UIView.animateKeyframes(
                withDuration: duration * 1.5, delay: 0,
                options: [.calculationModeLinear, .allowUserInteraction]
            ) { [self] in
                for i in 0..<infoContentsTextAnimateStep {
                    let dbi = Double(i)
                    let animationStep = Double(infoContentsTextAnimateStep)
                    UIView.addKeyframe(
                        withRelativeStartTime: dbi / animationStep, relativeDuration: 1 / dbi
                    ) { [self] in
                        filePathLabel.alpha = (1 / (animationStep / 4)) * (dbi + 1)
                        creationDateLabel.alpha = (1 / ((animationStep / 4) * 2)) * (dbi + 1)
                        itemSizeLabel.alpha = (1 / ((animationStep / 4) * 3)) * (dbi + 1)
                        [
                            totalDirectoryCountLabel, totalPageCountLabel, totalTextCountLabel, columnsLabel,
                            totalTableComponentCountLabel, totalAudioComponentCountLabel, totalAudioCountLabel,
                            totalAudioDurationLabel, textComponentSummaryLabel, mostRecentSnapshotDateLabel,
                            rowCountLabel,
                        ]
                        .forEach { $0.alpha = (1 / animationStep) * (dbi + 1) }
                    }
                }
            } completion: { [self] _ in
                longTapGesture.isEnabled = false
                titleLabel.isHidden = true

                fileItemTitleTextField.text = titleLabel.text!
                fileItemTitleTextField.isHidden = false
                fileItemTitleTextField.textColor = fileItemColor.color.title

                [moveButton, doneButton, hideButton, removeButton].forEach { $0.isUserInteractionEnabled = true }
            }
        }
    }

    private func setOriginAnimator(_ andThan: (() -> Void)? = nil) {
        let animator = UIViewPropertyAnimator(duration: duration, timingParameters: timing)
        containerView.isUserInteractionEnabled = false
        fileItemTitleTextField.isHidden = true
        titleLabel.isHidden = false

        animator.addAnimations { [self] in
            let views: [UIView] =
                [hideButton, removeButton, moveButton, doneButton, lineView, colorsView] + colorCircles + [
                    filePathLabel, creationDateLabel, itemSizeLabel, textComponentSummaryLabel,
                    totalAudioCountLabel, totalAudioDurationLabel, mostRecentSnapshotDateLabel,
                    totalDirectoryCountLabel, totalTextCountLabel, columnsLabel, rowCountLabel,
                    totalTableComponentCountLabel, totalAudioComponentCountLabel, totalPageCountLabel,
                ]
            views.forEach { $0.alpha = 0 }
        }

        animator.addAnimations { [self] in
            containerView.backgroundColor = containerView.backgroundColor?.withAlphaComponent(1)

            fileIconBarConstraints.forEach { $0.isActive = false }
            fileIconInfoConstraints.forEach { $0.isActive = false }

            titleLabelInfoConstraints.forEach { $0.isActive = false }
            titleLabelBarConstraints.forEach { $0.isActive = false }

            hideButtonInfoConstraints.forEach { $0.isActive = false }
            removeButtonInfoConstraints.forEach { $0.isActive = false }
            moveButtonInfoConstraints.forEach { $0.isActive = false }
            doneButtonInfoConstraints.forEach { $0.isActive = false }
            fileInformationScrollViewInfoConstraints.forEach { $0.isActive = false }

            fileIconDefaultConstraints.forEach { $0.isActive = true }
            titleLabelDefaultConstraints.forEach { $0.isActive = true }

            moveButtonDefaultConstraints.forEach { $0.isActive = true }
            doneButtonDefaultConstraints.forEach { $0.isActive = true }
            hideButtonDefaultConstraints.forEach { $0.isActive = true }
            removeButtonDefaultConstraints.forEach { $0.isActive = true }

            fileInformationScrollViewDefaultConstraints.forEach { $0.isActive = true }

            frame.size = originFrame
            frame.origin = originBlockPoint
            layer.zPosition = originZ

            lineViewWidthConstraint.constant = 1

            titleLabel.font = .systemFont(ofSize: 17)

            setFileItemSizeState()
            layoutIfNeeded()
        }

        animator.addAnimations { [self] in
            CATransaction.begin()
            CATransaction.setAnimationDuration(duration)
            CATransaction.setAnimationTimingFunction(
                CAMediaTimingFunction(
                    controlPoints: Float(timingParameterPoint.x), Float(timingParameterPoint.y),
                    Float(timingParameterPoint2.x), Float(timingParameterPoint2.y)
                )
            )

            innerShadowLayer.frame = bounds

            let path = UIBezierPath(roundedRect: bounds.insetBy(dx: -15, dy: -15), cornerRadius: cornerRadius)
            let cutout = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).reversing()
            path.append(cutout)

            let ba = CABasicAnimation(keyPath: "shadowPath")
            ba.fromValue = innerShadowLayer.shadowPath
            ba.toValue = path.cgPath

            let ba2 = CABasicAnimation(keyPath: "shadowOffset")
            ba2.fromValue = innerShadowLayer.shadowOffset
            ba2.toValue = CGSize(width: -1, height: 1)

            let g = CAAnimationGroup()
            g.animations = [ba, ba2]
            innerShadowLayer.add(g, forKey: nil)

            innerShadowLayer.cornerRadius = cornerRadius
            innerShadowLayer.shadowPath = path.cgPath
            innerShadowLayer.masksToBounds = true
            setInnerShadowColor()
            innerShadowLayer.shadowOffset = .init(width: -3, height: 3)
            innerShadowLayer.fillRule = .evenOdd

            CATransaction.commit()
        }

        animator.addCompletion { [self] _ in
            setFileItemSizeState()
            collectionViewRef?.addSubview(self)
            collectionViewRef?.allowsSelection = true
            frame.origin = originPoint

            blockView.removeFromSuperview()

            let views: [UIView] =
                [hideButton, removeButton, moveButton, doneButton, lineView, colorsView] + colorCircles + [
                    filePathLabel, creationDateLabel, itemSizeLabel,
                ]
            views.forEach { $0.isHidden = true }

            longTapGesture.isEnabled = true

            fileInformationScrollView.setContentOffset(.zero, animated: false)

            itemSizeLabel.attributedText =
                makeFileInfoAttrString(subTitle: "size : ", contentsString: "calculating...")
            totalAudioDurationLabel.attributedText =
                makeFileInfoAttrString(subTitle: "total playtime : ", contentsString: "calculating...")
            textComponentSummaryLabel.attributedText =
                makeFileInfoAttrString(subTitle: "summary\n", contentsString: "summarizing...")

            andThan?()
        }

        itemInformationVCPresentAnimator = animator
        animator.startAnimation()

        UIView.animate(withDuration: duration * 0.5, delay: 0, options: .curveLinear) { [self] in
            blockView.subviews.compactMap { $0 as? UIImageView }.first?.alpha = 0
        }

        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear) { [self] in
            colorStackViewInfoConstraints.forEach { $0.isActive = false }
            colorStackViewDefaultConstraints.forEach { $0.isActive = true }
        }
    }

    // MARK: -===================== Set Item Information Label =====================-

    func setTableInfoLabel(columns: String, rowCount: String) {
        columnsLabel.attributedText =
            makeFileInfoAttrString(subTitle: "columns\n", contentsString: columns)
        rowCountLabel.attributedText =
            makeFileInfoAttrString(subTitle: "rows : ", contentsString: rowCount)
    }

    func setMostRecentSnapshotDate(mostRecentSnpashotDate: String) {
        mostRecentSnapshotDateLabel.attributedText =
            makeFileInfoAttrString(subTitle: "most recent snapshot date\n", contentsString: mostRecentSnpashotDate)
    }

    func setItemSize(size: String) {
        itemSizeLabel.attributedText = makeFileInfoAttrString(subTitle: "size : ", contentsString: size)
    }

    func setTextComponentSummary(summary: String) {
        UIView.transition(
            with: textComponentSummaryLabel,
            duration: 0.3,
            options: .transitionCrossDissolve
        ) { [self] in
            textComponentSummaryLabel.attributedText =
                makeFileInfoAttrString(subTitle: "summary\n", contentsString: summary, contentFontSize: 15)
        }
    }

    func setAudioTotalDuration(duration: String) {
        totalAudioDurationLabel.attributedText =
            makeFileInfoAttrString(subTitle: "total playtime : ", contentsString: duration)
    }

    func setAudioTotalCount(audioTotalCount: String) {
        totalAudioCountLabel.attributedText =
            makeFileInfoAttrString(subTitle: "audio tracks : ", contentsString: audioTotalCount)
    }

    func setInnerFileCount(dirCount: String, pageCount: String) {
        totalDirectoryCountLabel.attributedText =
            makeFileInfoAttrString(subTitle: "directories : ", contentsString: dirCount)
        totalPageCountLabel.attributedText =
            makeFileInfoAttrString(subTitle: "pages : ", contentsString: pageCount)
    }

    func setPageInfo(componentCounts: [ComponentType: Int]) {
        totalTextCountLabel.attributedText =
            makeFileInfoAttrString(
                subTitle: "text editor notes : ",
                contentsString: "\(componentCounts[.text, default: 0])")
        totalTableComponentCountLabel.attributedText =
            makeFileInfoAttrString(
                subTitle: "table notes : ",
                contentsString: "\(componentCounts[.table, default: 0])")
        totalAudioComponentCountLabel.attributedText =
            makeFileInfoAttrString(
                subTitle: "audio notes : ",
                contentsString: "\(componentCounts[.audio, default: 0])")
    }

    private func makeFileInfoAttrString(subTitle: String, contentsString: String, contentFontSize: Double = 18)
        -> NSMutableAttributedString
    {
        let attributedString = NSMutableAttributedString()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.lineBreakMode = .byWordWrapping

        attributedString.append(
            NSAttributedString(
                string: subTitle,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 17),
                    .foregroundColor: UIColor.gray,
                ]
            )
        )

        attributedString.append(
            NSAttributedString(
                string: contentsString,
                attributes: [
                    .font: UIFont.systemFont(ofSize: contentFontSize, weight: .semibold),
                    .foregroundColor: UIColor.black,
                ]
            )
        )

        attributedString.append(
            NSAttributedString(
                string: infoLabelDivisionDottedLine,
                attributes: [.font: infoLabelDivisionDottedLineFont, .foregroundColor: UIColor.systemGray3]
            )
        )

        attributedString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: attributedString.length)
        )
        return attributedString
    }

    // MARK: -===================== Editing Item Title =====================-

    func textFieldDidChangeSelection(_ textField: UITextField) {
        if let text = textField.text {
            if text.count > 32 {
                textField.text = String(text.dropLast())
                titleLabel.text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            } else if text.isEmpty {
                textField.placeholder = "no title"
                titleLabel.text = "no title"
            } else {
                titleLabel.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            dispatcher?.send(.willChangeFileName(itemID!, titleLabel.text!))
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: -===================== Configuration =====================-

    func configure(
        with fileItem: some StorageItem,
        dispatcher: PassthroughSubject<MemoHomeViewInput, Never>,
        isActivePanGesture: Bool,
        isActiveLongTapGesture: Bool
    ) {
        self.dispatcher = dispatcher
        self.itemID = fileItem.id
        self.titleLabel.text = fileItem.name
        self.panGesture.isEnabled = isActivePanGesture
        self.longTapGesture.isEnabled = isActiveLongTapGesture
        self.fileItemColor = fileItem.itemColor
        self.filePathLabel.attributedText =
            makeFileInfoAttrString(subTitle: "location\n", contentsString: fileItem.getFilePath())
        self.creationDateLabel.attributedText =
            makeFileInfoAttrString(subTitle: "creation date\n", contentsString: fileItem.creationDate.formattedDate)
        self.itemSizeLabel.attributedText =
            makeFileInfoAttrString(subTitle: "size : ", contentsString: "calculating...")

        containerView.backgroundColor = fileItem.itemColor.color.bg
        titleLabel.textColor = fileItem.itemColor.color.title

        if fileItem as? MemoDirectoryModel != nil {
            fileIconImageView.image = UIImage(named: "folder")?.resized(to: .init(width: 60, height: 60))
            totalDirectoryCountLabel.isHidden = false
            totalPageCountLabel.isHidden = false
        } else if let page = fileItem as? MemoPageModel {
            if page.isSingleComponentPage {
                switch page.components.first!.type {
                    case .text:
                        fileIconImageView.image = UIImage(named: "text")?.resized(to: .init(width: 60, height: 60))
                        textComponentSummaryLabel.isHidden = false
                        mostRecentSnapshotDateLabel.isHidden = false
                        textComponentSummaryLabel.isHidden = false
                        textComponentSummaryLabel.attributedText =
                            makeFileInfoAttrString(subTitle: "summary\n", contentsString: "summarizing...")

                    case .table:
                        fileIconImageView.image = UIImage(named: "table")?.resized(to: .init(width: 60, height: 60))
                        mostRecentSnapshotDateLabel.isHidden = false
                        columnsLabel.isHidden = false
                        rowCountLabel.isHidden = false

                    case .audio:
                        fileIconImageView.image = UIImage(named: "audio")?.resized(to: .init(width: 60, height: 60))
                        totalAudioDurationLabel.isHidden = false
                        totalAudioCountLabel.isHidden = false
                }
            } else {
                fileIconImageView.image = UIImage(named: "multi")?.resized(to: .init(width: 60, height: 60))
                totalTextCountLabel.isHidden = false
                totalTableComponentCountLabel.isHidden = false
                totalAudioComponentCountLabel.isHidden = false
            }
        }
        setFileItemSizeState()
        setInnerShadowLayer()
    }
}

extension FileItemView: UIGestureRecognizerDelegate {
    @objc private func handlePanGesture(_ gr: UIPanGestureRecognizer) {
        collectionView?.alwaysBounceVertical = false
        collectionView?.isScrollEnabled = false

        switch gr.state {
            case .began:
                let location = gr.location(in: contentView)
                beganPointInWindow = gr.location(in: collectionView)

                let nx = min(max(location.x / contentView.bounds.width, 0), 1)
                let ny = min(max(location.y / contentView.bounds.height, 0), 1)
                scaledBeganPoint = CGPoint(x: nx, y: ny)

                UIView.animate(withDuration: 0.3) {
                    Self.z += 1
                    self.layer.zPosition = Self.z
                    self.alpha = 0.4
                    self.layer.borderWidth = 3
                }

            case .changed:
                if let scaledBeganPoint {
                    let location = gr.location(in: contentView)
                    let isBeganTrailing = scaledBeganPoint.x >= 0.7
                    let isBeganBottom = scaledBeganPoint.y >= 0.7

                    if isBeganTrailing && isBeganBottom {
                        let w = collectionView!.frame.size.width
                        let leftWall = gr.location(in: collectionView).x

                        if w >= leftWall {
                            frame.size.width = min(
                                UIConstants.ItemSize.large.size.width,
                                max(UIConstants.ItemSize.small.size.width, location.x))
                        }
                        frame.size.height = min(
                            UIConstants.ItemSize.large.size.height,
                            max(UIConstants.ItemSize.small.size.height, location.y))
                    } else {
                        let translation = gr.translation(in: contentView)
                        let maxX = collectionView!.frame.width - frame.width
                        let proposedX = frame.origin.x + translation.x
                        let proposedY = frame.origin.y + translation.y

                        frame.origin.x = min(max(0, proposedX), maxX)
                        frame.origin.y = max(0, proposedY)
                        gr.setTranslation(.zero, in: contentView)
                    }
                    self.setFileItemSizeState()
                }

            case .ended, .cancelled, .failed:
                UIView.animate(withDuration: 0.3) {
                    self.alpha = 1
                    self.layer.borderWidth = 0
                }

                dispatcher?.send(.willSortManualOrder(itemID!, frame))
                collectionView?.alwaysBounceVertical = true
                collectionView?.isScrollEnabled = true

            default: break
        }
    }

    @objc private func longTapGestureHandler(gr: UILongPressGestureRecognizer) {
        switch gr.state {
            case .began: setAnimator()
            case .changed, .cancelled, .ended, .failed, .recognized, .possible: break
            @unknown default: break
        }
    }
}

enum FileItemColor: String, Codable, CaseIterable {
    case red = "RED"
    case green = "GREEN"
    case purple = "PURPLE"
    case blue = "BLUE"
    case orange = "ORANGE"
    case white = "WHITE"

    var color: (bg: UIColor?, title: UIColor?) {
        switch self {
            case .red: (UIColor(hex: "#FCE8EB"), .systemRed)
            case .green: (UIColor(hex: "#DAF5DE"), .systemGreen)
            case .purple: (UIColor(hex: "#E6DFF5"), .systemPurple)
            case .blue: (UIColor(hex: "#D7E9F5"), .systemBlue)
            case .orange: (UIColor(hex: "#FCEAB8"), .systemOrange)
            case .white: (UIColor(named: "FixedFileItemBackgroundColor"), .black)
        }
    }
}
