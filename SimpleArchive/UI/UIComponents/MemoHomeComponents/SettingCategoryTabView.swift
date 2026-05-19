import UIKit

final class SettingCategoryTabView: UIView, BaseColorUpdatable {
    private enum Tab {
        case appearance
        case note
        case signature
    }

    private(set) lazy var paintingImageView: UIImageView = {
        let paintingImageView = UIImageView()
        paintingImageView.translatesAutoresizingMaskIntoConstraints = false
        paintingImageView.contentMode = .scaleAspectFit
        paintingImageView.image = UIImage(named: "painting")?
            .resized(to: CGSize(width: 30, height: 30))
            .withRenderingMode(.alwaysTemplate)
        return paintingImageView
    }()
    private(set) var appearanceLabel: UILabel = {
        let appearanceLabel = UILabel()
        appearanceLabel.text = "Appearance"
        appearanceLabel.font = .systemFont(ofSize: 21, weight: .semibold)
        appearanceLabel.translatesAutoresizingMaskIntoConstraints = false
        appearanceLabel.setContentHuggingPriority(.required, for: .horizontal)
        appearanceLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return appearanceLabel
    }()
    private var appearanceContentView: UIView = {
        let appearanceContentView = UIView()
        appearanceContentView.translatesAutoresizingMaskIntoConstraints = false
        return appearanceContentView
    }()
    private var appearanceTabView: UIView = {
        let appearanceTabView = UIView()
        appearanceTabView.translatesAutoresizingMaskIntoConstraints = false
        return appearanceTabView
    }()

    private(set) lazy var noteImageView: UIImageView = {
        let noteImageView = UIImageView()
        noteImageView.translatesAutoresizingMaskIntoConstraints = false
        noteImageView.contentMode = .scaleAspectFit
        noteImageView.image = UIImage(named: "note")?
            .resized(to: CGSize(width: 30, height: 30))
            .withRenderingMode(.alwaysTemplate)
        return noteImageView
    }()
    private(set) var noteLabel: UILabel = {
        let noteLabel = UILabel()
        noteLabel.text = "Note"
        noteLabel.font = .systemFont(ofSize: 21, weight: .semibold)
        noteLabel.translatesAutoresizingMaskIntoConstraints = false
        noteLabel.setContentHuggingPriority(.required, for: .horizontal)
        noteLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return noteLabel
    }()
    private var noteContentView: UIView = {
        let noteContentView = UIView()
        noteContentView.translatesAutoresizingMaskIntoConstraints = false
        return noteContentView
    }()
    private var noteTabView: UIView = {
        let noteTabView = UIView()
        noteTabView.translatesAutoresizingMaskIntoConstraints = false
        return noteTabView
    }()

    private(set) lazy var drawingImageView: UIImageView = {
        let drawingImageView = UIImageView()
        drawingImageView.translatesAutoresizingMaskIntoConstraints = false
        drawingImageView.contentMode = .scaleAspectFit
        drawingImageView.image = UIImage(named: "drawing")?
            .resized(to: CGSize(width: 30, height: 30))
            .withRenderingMode(.alwaysTemplate)
        return drawingImageView
    }()
    private(set) var signatureLabel: UILabel = {
        let signatureLabel = UILabel()
        signatureLabel.text = "Signature"
        signatureLabel.font = .systemFont(ofSize: 21, weight: .semibold)
        signatureLabel.translatesAutoresizingMaskIntoConstraints = false
        signatureLabel.setContentHuggingPriority(.required, for: .horizontal)
        signatureLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return signatureLabel
    }()
    private var signatureContentView: UIView = {
        let signatureContentView = UIView()
        signatureContentView.translatesAutoresizingMaskIntoConstraints = false
        return signatureContentView
    }()
    private var signatureTabView: UIView = {
        let signatureTabView = UIView()
        signatureTabView.translatesAutoresizingMaskIntoConstraints = false
        return signatureTabView
    }()
    private(set) var lineView: UIView = {
        let lineView = UIView()
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.layer.cornerRadius = 1.5
        return lineView
    }()

    private let tabHeight: CGFloat = 30
    private let tabSpacing: CGFloat = 15
    private let iconSize: CGFloat = 30
    private let activeIconSpacing: CGFloat = 3
    private let tabToLineSpacing: CGFloat = 3
    private var selectedTab: Tab = .appearance

    private var lineWidthConstraint: NSLayoutConstraint!
    private var lineCenterXConstraint: NSLayoutConstraint!
    private var appearanceTabWidthConstraint: NSLayoutConstraint!
    private var noteTabWidthConstraint: NSLayoutConstraint!
    private var signatureTabWidthConstraint: NSLayoutConstraint!
    private var appearanceContentWidthConstraint: NSLayoutConstraint!
    private var noteContentWidthConstraint: NSLayoutConstraint!
    private var signatureContentWidthConstraint: NSLayoutConstraint!
    private var appearanceLabelLeadingConstraint: NSLayoutConstraint!
    private var noteLabelLeadingConstraint: NSLayoutConstraint!
    private var signatureLabelLeadingConstraint: NSLayoutConstraint!
    private var appearanceLabelWidthConstraint: NSLayoutConstraint!
    private var noteLabelWidthConstraint: NSLayoutConstraint!
    private var signatureLabelWidthConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        appearanceTabView.addSubview(appearanceContentView)
        appearanceContentView.addSubview(paintingImageView)
        appearanceContentView.addSubview(appearanceLabel)
        addSubview(appearanceTabView)

        noteTabView.addSubview(noteContentView)
        noteContentView.addSubview(noteImageView)
        noteContentView.addSubview(noteLabel)
        addSubview(noteTabView)

        signatureTabView.addSubview(signatureContentView)
        signatureContentView.addSubview(drawingImageView)
        signatureContentView.addSubview(signatureLabel)

        addSubview(signatureTabView)
        addSubview(lineView)

        noteLabel.alpha = 0
        signatureLabel.alpha = 0
    }

    private func setupConstraints() {
        lineWidthConstraint = lineView.widthAnchor.constraint(
            equalToConstant: lineWidthConstant(for: .appearance)
        )
        lineCenterXConstraint = lineView.centerXAnchor.constraint(equalTo: appearanceContentView.centerXAnchor)
        appearanceTabWidthConstraint = appearanceTabView.widthAnchor.constraint(
            equalToConstant: activeContentWidth(label: appearanceLabel)
        )
        noteTabWidthConstraint = noteTabView.widthAnchor.constraint(equalToConstant: iconSize)
        signatureTabWidthConstraint = signatureTabView.widthAnchor.constraint(equalToConstant: iconSize)
        appearanceContentWidthConstraint = appearanceContentView.widthAnchor.constraint(
            equalToConstant: activeContentWidth(label: appearanceLabel)
        )
        noteContentWidthConstraint = noteContentView.widthAnchor.constraint(equalToConstant: iconSize)
        signatureContentWidthConstraint = signatureContentView.widthAnchor.constraint(equalToConstant: iconSize)
        appearanceLabelLeadingConstraint = appearanceLabel.leadingAnchor.constraint(
            equalTo: paintingImageView.trailingAnchor, constant: activeIconSpacing)
        noteLabelLeadingConstraint = noteLabel.leadingAnchor.constraint(
            equalTo: noteImageView.trailingAnchor, constant: 0)
        signatureLabelLeadingConstraint = signatureLabel.leadingAnchor.constraint(
            equalTo: drawingImageView.trailingAnchor, constant: 0)
        appearanceLabelWidthConstraint = appearanceLabel.widthAnchor.constraint(
            equalToConstant: labelWidth(appearanceLabel)
        )
        noteLabelWidthConstraint = noteLabel.widthAnchor.constraint(equalToConstant: 0)
        signatureLabelWidthConstraint = signatureLabel.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            appearanceTabView.leadingAnchor.constraint(equalTo: leadingAnchor),
            appearanceTabWidthConstraint,
            appearanceTabView.heightAnchor.constraint(equalToConstant: tabHeight),
            appearanceTabView.bottomAnchor.constraint(equalTo: lineView.topAnchor, constant: -tabToLineSpacing),

            appearanceContentView.centerXAnchor.constraint(equalTo: appearanceTabView.centerXAnchor),
            appearanceContentView.bottomAnchor.constraint(equalTo: appearanceTabView.bottomAnchor),
            appearanceContentWidthConstraint,

            paintingImageView.leadingAnchor.constraint(equalTo: appearanceContentView.leadingAnchor),
            paintingImageView.topAnchor.constraint(equalTo: appearanceContentView.topAnchor),
            paintingImageView.bottomAnchor.constraint(equalTo: appearanceContentView.bottomAnchor),
            paintingImageView.heightAnchor.constraint(equalToConstant: iconSize),
            paintingImageView.widthAnchor.constraint(equalToConstant: iconSize),

            appearanceLabelLeadingConstraint,
            appearanceLabelWidthConstraint,
            appearanceLabel.bottomAnchor.constraint(equalTo: appearanceContentView.bottomAnchor),

            noteTabView.leadingAnchor.constraint(equalTo: appearanceTabView.trailingAnchor, constant: tabSpacing),
            noteTabWidthConstraint,
            noteTabView.heightAnchor.constraint(equalToConstant: tabHeight),
            noteTabView.bottomAnchor.constraint(equalTo: lineView.topAnchor, constant: -tabToLineSpacing),

            noteContentView.centerXAnchor.constraint(equalTo: noteTabView.centerXAnchor),
            noteContentView.bottomAnchor.constraint(equalTo: noteTabView.bottomAnchor),
            noteContentWidthConstraint,

            noteImageView.leadingAnchor.constraint(equalTo: noteContentView.leadingAnchor),
            noteImageView.topAnchor.constraint(equalTo: noteContentView.topAnchor),
            noteImageView.bottomAnchor.constraint(equalTo: noteContentView.bottomAnchor),
            noteImageView.heightAnchor.constraint(equalToConstant: iconSize),
            noteImageView.widthAnchor.constraint(equalToConstant: iconSize),

            noteLabelLeadingConstraint,
            noteLabelWidthConstraint,
            noteLabel.bottomAnchor.constraint(equalTo: noteContentView.bottomAnchor),

            signatureTabView.leadingAnchor.constraint(equalTo: noteTabView.trailingAnchor, constant: tabSpacing),
            signatureTabWidthConstraint,
            signatureTabView.heightAnchor.constraint(equalToConstant: tabHeight),
            signatureTabView.bottomAnchor.constraint(equalTo: lineView.topAnchor, constant: -tabToLineSpacing),

            signatureContentView.centerXAnchor.constraint(equalTo: signatureTabView.centerXAnchor),
            signatureContentView.bottomAnchor.constraint(equalTo: signatureTabView.bottomAnchor),
            signatureContentWidthConstraint,

            drawingImageView.leadingAnchor.constraint(equalTo: signatureContentView.leadingAnchor),
            drawingImageView.topAnchor.constraint(equalTo: signatureContentView.topAnchor),
            drawingImageView.bottomAnchor.constraint(equalTo: signatureContentView.bottomAnchor),
            drawingImageView.heightAnchor.constraint(equalToConstant: iconSize),
            drawingImageView.widthAnchor.constraint(equalToConstant: iconSize),

            signatureLabelLeadingConstraint,
            signatureLabelWidthConstraint,
            signatureLabel.bottomAnchor.constraint(equalTo: signatureContentView.bottomAnchor),

            lineView.heightAnchor.constraint(equalToConstant: 3),
            lineView.bottomAnchor.constraint(equalTo: bottomAnchor),
            lineCenterXConstraint,
            lineWidthConstraint,
        ])
    }

    private func updateSelection(to tab: Tab) {
        selectedTab = tab

        let isAppearanceSelected = tab == .appearance
        let isNoteSelected = tab == .note
        let isSignatureSelected = tab == .signature

        updateTabLayout(
            tabWidthConstraint: appearanceTabWidthConstraint,
            contentWidthConstraint: appearanceContentWidthConstraint,
            labelLeadingConstraint: appearanceLabelLeadingConstraint,
            labelWidthConstraint: appearanceLabelWidthConstraint,
            label: appearanceLabel,
            isSelected: isAppearanceSelected
        )
        updateTabLayout(
            tabWidthConstraint: noteTabWidthConstraint,
            contentWidthConstraint: noteContentWidthConstraint,
            labelLeadingConstraint: noteLabelLeadingConstraint,
            labelWidthConstraint: noteLabelWidthConstraint,
            label: noteLabel,
            isSelected: isNoteSelected
        )
        updateTabLayout(
            tabWidthConstraint: signatureTabWidthConstraint,
            contentWidthConstraint: signatureContentWidthConstraint,
            labelLeadingConstraint: signatureLabelLeadingConstraint,
            labelWidthConstraint: signatureLabelWidthConstraint,
            label: signatureLabel,
            isSelected: isSignatureSelected
        )

        lineView.transform = .identity
        lineWidthConstraint.constant = lineWidthConstant(for: tab)
        updateLineCenterXConstraint(for: tab)
    }

    private func lineWidthConstant(for tab: Tab) -> CGFloat {
        switch tab {
            case .appearance:
                return activeContentWidth(label: appearanceLabel)
            case .note:
                return activeContentWidth(label: noteLabel)
            case .signature:
                return activeContentWidth(label: signatureLabel)
        }
    }

    private func activeContentWidth(label: UILabel) -> CGFloat {
        iconSize + activeIconSpacing + labelWidth(label)
    }

    private func updateLineCenterXConstraint(for tab: Tab) {
        lineCenterXConstraint.isActive = false
        switch tab {
            case .appearance:
                lineCenterXConstraint = lineView.centerXAnchor.constraint(equalTo: appearanceContentView.centerXAnchor)
            case .note:
                lineCenterXConstraint = lineView.centerXAnchor.constraint(equalTo: noteContentView.centerXAnchor)
            case .signature:
                lineCenterXConstraint = lineView.centerXAnchor.constraint(equalTo: signatureContentView.centerXAnchor)
        }
        lineCenterXConstraint.isActive = true
    }

    private func updateTabLayout(
        tabWidthConstraint: NSLayoutConstraint,
        contentWidthConstraint: NSLayoutConstraint,
        labelLeadingConstraint: NSLayoutConstraint,
        labelWidthConstraint: NSLayoutConstraint,
        label: UILabel,
        isSelected: Bool
    ) {
        let width = isSelected ? activeContentWidth(label: label) : iconSize
        tabWidthConstraint.constant = width
        contentWidthConstraint.constant = width
        labelLeadingConstraint.constant = isSelected ? activeIconSpacing : 0
        labelWidthConstraint.constant = isSelected ? labelWidth(label) : 0
        label.alpha = isSelected ? 1 : 0
    }

    private func labelWidth(_ label: UILabel) -> CGFloat {
        label.intrinsicContentSize.width
    }

    func selectTab(forPageIndex index: Int) {
        let targetTab: Tab
        switch index {
            case 0: targetTab = .appearance
            case 1: targetTab = .note
            default: targetTab = .signature
        }
        updateSelection(to: targetTab)
    }

    func applyColor(_ colorManager: any AppAppearanceManagerType = AppAppearanceManager.shared) {
        paintingImageView.tintColor = colorManager.appTintColor
        noteImageView.tintColor = colorManager.appTintColor
        drawingImageView.tintColor = colorManager.appTintColor
        lineView.backgroundColor = colorManager.appTintColor
        appearanceLabel.textColor = colorManager.appTintColor
        noteLabel.textColor = colorManager.appTintColor
        signatureLabel.textColor = colorManager.appTintColor
    }
}
