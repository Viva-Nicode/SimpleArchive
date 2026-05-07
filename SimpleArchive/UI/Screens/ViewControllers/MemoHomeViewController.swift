import Combine
import UIKit

final class MemoHomeViewController: UIViewController {
    private(set) var titleLabelView: UIView = {
        let titleLabelView = UIView()

        titleLabelView.layer.shadowColor = UIColor.black.cgColor
        titleLabelView.layer.shadowOffset = .init(width: -4, height: 4)
        titleLabelView.layer.shadowOpacity = 0.1
        titleLabelView.layer.shadowRadius = 4
        titleLabelView.layer.cornerRadius = 10
        titleLabelView.translatesAutoresizingMaskIntoConstraints = false

        let innerShadowLayer = CAShapeLayer()
        let size = CGRect(x: 0, y: 0, width: 190, height: 140)
        innerShadowLayer.frame = size
        titleLabelView.layer.addSublayer(innerShadowLayer)

        let path = UIBezierPath(roundedRect: size.insetBy(dx: -15, dy: -15), cornerRadius: 10)
        let cutout = UIBezierPath(roundedRect: size, cornerRadius: 10).reversing()
        path.append(cutout)

        innerShadowLayer.cornerRadius = 10
        innerShadowLayer.shadowPath = path.cgPath
        innerShadowLayer.masksToBounds = true
        innerShadowLayer.shadowColor = UIColor.black.cgColor
        innerShadowLayer.shadowOffset = .init(width: -3, height: 3)
        innerShadowLayer.shadowOpacity = 0.07
        innerShadowLayer.shadowRadius = 4
        innerShadowLayer.fillRule = .evenOdd
        titleLabelView.backgroundColor = .appBaseColor

        return titleLabelView
    }()
    private(set) lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .left

        titleAttributedString.append(
            NSAttributedString(
                string: "Home\n",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                    .foregroundColor: UIColor.appTintColor,
                ]
            )
        )

        let w = ("-" as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 18)]).width
        let c = Int(170 / w)

        titleAttributedString.append(
            NSAttributedString(
                string: String(repeating: "-", count: c) + "\n",
                attributes: [.font: UIFont.systemFont(ofSize: 18), .foregroundColor: UIColor.systemGray3]
            )
        )

        titleAttributedString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: titleAttributedString.length)
        )

        titleLabel.attributedText = titleAttributedString
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()
    private(set) var trashBoxButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "trash")
        config.baseForegroundColor = .black
        config.preferredSymbolConfigurationForImage = .init(pointSize: 20, weight: .regular)
        config.cornerStyle = .fixed
        config.background.cornerRadius = 10

        let button = UIButton(configuration: config)
        let innerShadowLayer = CAShapeLayer()
        let size = CGRect(x: 0, y: 0, width: 55, height: 55)

        innerShadowLayer.frame = size
        button.layer.addSublayer(innerShadowLayer)

        let path = UIBezierPath(roundedRect: size.insetBy(dx: -15, dy: -15), cornerRadius: 10)
        let cutout = UIBezierPath(roundedRect: size, cornerRadius: 10).reversing()
        path.append(cutout)

        innerShadowLayer.shadowPath = path.cgPath
        innerShadowLayer.shadowOffset = .init(width: -3, height: 3)
        innerShadowLayer.cornerRadius = 10
        innerShadowLayer.masksToBounds = true
        innerShadowLayer.shadowColor = UIColor.black.cgColor
        innerShadowLayer.shadowOpacity = 0.07
        innerShadowLayer.shadowRadius = 4
        innerShadowLayer.fillRule = .evenOdd

        button.backgroundColor = .appBaseColor
		button.layer.cornerRadius = 10
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = .init(width: -4, height: 4)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 4
        button.layer.masksToBounds = false
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()
    private(set) var sortingOptionsView: UIView = {
        let sortingOptionsView = UIView()
        sortingOptionsView.backgroundColor = .appBaseColor
        sortingOptionsView.layer.cornerRadius = 20
        sortingOptionsView.layer.shadowColor = UIColor.black.cgColor
        sortingOptionsView.layer.shadowOffset = .init(width: -2, height: 2)
        sortingOptionsView.layer.shadowOpacity = 0.1
        sortingOptionsView.layer.shadowRadius = 4
        sortingOptionsView.translatesAutoresizingMaskIntoConstraints = false
        return sortingOptionsView
    }()
    private(set) var sortByManumalLabel: UILabel = {
        let sortByManumalLabel = BasePaddingLabel(padding: .init(top: 5, left: 15, bottom: 5, right: 15))
        sortByManumalLabel.text = "manual"
        sortByManumalLabel.textColor = .systemGray4
        sortByManumalLabel.isUserInteractionEnabled = true
        sortByManumalLabel.font = .systemFont(ofSize: 16, weight: .regular)
        sortByManumalLabel.translatesAutoresizingMaskIntoConstraints = false
        sortByManumalLabel.backgroundColor = .appBaseColor
        sortByManumalLabel.layer.cornerRadius = 15
        sortByManumalLabel.clipsToBounds = true

        let innerShadowLayer = CAShapeLayer()
        let size = CGRect(origin: .init(x: 0, y: 0), size: sortByManumalLabel.intrinsicContentSize)
        innerShadowLayer.frame = size
        sortByManumalLabel.layer.addSublayer(innerShadowLayer)

        let path = UIBezierPath(roundedRect: size.insetBy(dx: -15, dy: -15), cornerRadius: 15)
        let cutout = UIBezierPath(roundedRect: size, cornerRadius: 15).reversing()
        path.append(cutout)

        innerShadowLayer.cornerRadius = 15
        innerShadowLayer.shadowPath = path.cgPath
        innerShadowLayer.masksToBounds = true
        innerShadowLayer.shadowColor = UIColor.black.cgColor
        innerShadowLayer.shadowOffset = .init(width: -3, height: 3)
        innerShadowLayer.shadowOpacity = 0.07
        innerShadowLayer.shadowRadius = 4
        innerShadowLayer.fillRule = .evenOdd
        innerShadowLayer.opacity = 0
        return sortByManumalLabel
    }()
    private(set) var sortByNameLabel: UILabel = {
        let sortByNameLabel = BasePaddingLabel(padding: .init(top: 5, left: 15, bottom: 5, right: 15))
        sortByNameLabel.text = "name"
        sortByNameLabel.textColor = .systemGray4
        sortByNameLabel.isUserInteractionEnabled = true
        sortByNameLabel.font = .systemFont(ofSize: 16, weight: .regular)
        sortByNameLabel.translatesAutoresizingMaskIntoConstraints = false
        sortByNameLabel.backgroundColor = .appBaseColor
        sortByNameLabel.layer.cornerRadius = 15
        sortByNameLabel.clipsToBounds = true

        let innerShadowLayer = CAShapeLayer()
        let size = CGRect(origin: .init(x: 0, y: 0), size: sortByNameLabel.intrinsicContentSize)
        innerShadowLayer.frame = size
        sortByNameLabel.layer.addSublayer(innerShadowLayer)

        let path = UIBezierPath(roundedRect: size.insetBy(dx: -15, dy: -15), cornerRadius: 15)
        let cutout = UIBezierPath(roundedRect: size, cornerRadius: 15).reversing()
        path.append(cutout)

        innerShadowLayer.cornerRadius = 15
        innerShadowLayer.shadowPath = path.cgPath
        innerShadowLayer.masksToBounds = true
        innerShadowLayer.shadowColor = UIColor.black.cgColor
        innerShadowLayer.shadowOffset = .init(width: -3, height: 3)
        innerShadowLayer.shadowOpacity = 0.07
        innerShadowLayer.shadowRadius = 4
        innerShadowLayer.fillRule = .evenOdd
        innerShadowLayer.opacity = 0
        return sortByNameLabel
    }()
    private(set) var sortByCreatedateLabel: UILabel = {
        let sortByCreatedateLabel = BasePaddingLabel(padding: .init(top: 5, left: 15, bottom: 5, right: 15))
        sortByCreatedateLabel.text = "create date"
        sortByCreatedateLabel.textColor = .systemGray4
        sortByCreatedateLabel.isUserInteractionEnabled = true
        sortByCreatedateLabel.font = .systemFont(ofSize: 16, weight: .regular)
        sortByCreatedateLabel.translatesAutoresizingMaskIntoConstraints = false
        sortByCreatedateLabel.backgroundColor = .appBaseColor
        sortByCreatedateLabel.layer.cornerRadius = 15
        sortByCreatedateLabel.clipsToBounds = true

        let innerShadowLayer = CAShapeLayer()
        let size = CGRect(origin: .init(x: 0, y: 0), size: sortByCreatedateLabel.intrinsicContentSize)
        innerShadowLayer.frame = size
        sortByCreatedateLabel.layer.addSublayer(innerShadowLayer)

        let path = UIBezierPath(roundedRect: size.insetBy(dx: -15, dy: -15), cornerRadius: 15)
        let cutout = UIBezierPath(roundedRect: size, cornerRadius: 15).reversing()
        path.append(cutout)

        innerShadowLayer.cornerRadius = 15
        innerShadowLayer.shadowPath = path.cgPath
        innerShadowLayer.masksToBounds = true
        innerShadowLayer.shadowColor = UIColor.black.cgColor
        innerShadowLayer.shadowOffset = .init(width: -3, height: 3)
        innerShadowLayer.shadowOpacity = 0.07
        innerShadowLayer.shadowRadius = 4
        innerShadowLayer.fillRule = .evenOdd
        innerShadowLayer.opacity = 0
        return sortByCreatedateLabel
    }()
    private(set) var directoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.accessibilityIdentifier = "memoHomeCollectionView"
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(
            MemoHomeDirectoryContentCell.self,
            forCellWithReuseIdentifier: MemoHomeDirectoryContentCell.reuseIdentifier)
        collectionView.isPrefetchingEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    private(set) var createPageButton: UIView = {
        let image = UIImage(named: "file-plus")?.withTintColor(.label, renderingMode: .alwaysOriginal)
        let buttonImageView = UIImageView(image: image)
        buttonImageView.tintColor = .label
        buttonImageView.contentMode = .scaleAspectFit
        buttonImageView.frame = CGRect(x: 15.5, y: 15.5, width: 24, height: 24)
        $0.addSubview(buttonImageView)
        $0.alpha = 0
        $0.layer.cornerRadius = 27.5
        $0.backgroundColor = .clear
        $0.layer.masksToBounds = false
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOffset = .init(width: 0, height: 0)
        $0.layer.shadowOpacity = 0.2
        $0.layer.shadowRadius = 4

        let blurBackgroundView: UIVisualEffectView = {
            let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            let blurView = UIVisualEffectView(effect: blurEffect)

            blurView.layer.cornerRadius = 27.5
            blurView.isUserInteractionEnabled = false
            blurView.clipsToBounds = true
            blurView.layer.borderWidth = 1
            blurView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor

            return blurView
        }()

        blurBackgroundView.frame = $0.bounds
        blurBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        $0.addSubview(blurBackgroundView)
        $0.sendSubviewToBack(blurBackgroundView)
        return $0
    }(UIView())
    private(set) var createFolderButton: UIView = {
        let image = UIImage(named: "folder-plus")?.withTintColor(.label, renderingMode: .alwaysOriginal)
        let buttonImageView = UIImageView(image: image)
        buttonImageView.tintColor = .label
        buttonImageView.contentMode = .scaleAspectFit
        buttonImageView.frame = CGRect(x: 15.5, y: 15.5, width: 24, height: 24)
        $0.addSubview(buttonImageView)
        $0.alpha = 0
        $0.layer.cornerRadius = 27.5
        $0.backgroundColor = .clear
        $0.layer.masksToBounds = false
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOffset = .init(width: 0, height: 0)
        $0.layer.shadowOpacity = 0.2
        $0.layer.shadowRadius = 4

        let blurBackgroundView: UIVisualEffectView = {
            let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            let blurView = UIVisualEffectView(effect: blurEffect)

            blurView.layer.cornerRadius = 27.5
            blurView.isUserInteractionEnabled = false
            blurView.clipsToBounds = true
            blurView.layer.borderWidth = 1
            blurView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor

            return blurView
        }()

        blurBackgroundView.frame = $0.bounds
        blurBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        $0.addSubview(blurBackgroundView)
        $0.sendSubviewToBack(blurBackgroundView)
        return $0
    }(UIView())
    private(set) var fileCreatePlusButton: UIView = {
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let buttonImageView = UIImageView(image: UIImage(systemName: "plus", withConfiguration: config))
        buttonImageView.tintColor = .label
        buttonImageView.contentMode = .scaleAspectFit
        buttonImageView.frame = CGRect(x: 13, y: 13, width: 29, height: 29)
        $0.addSubview(buttonImageView)
        $0.layer.cornerRadius = 27.5
        $0.backgroundColor = .clear
        $0.layer.masksToBounds = false
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOffset = .init(width: 0, height: 0)
        $0.layer.shadowOpacity = 0.2
        $0.layer.shadowRadius = 4
        $0.accessibilityIdentifier = "MemoHomeVC.fileCreatePlusButton"

        let blurBackgroundView: UIVisualEffectView = {
            let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            let blurView = UIVisualEffectView(effect: blurEffect)

            blurView.layer.cornerRadius = 27.5
            blurView.isUserInteractionEnabled = false
            blurView.clipsToBounds = true
            blurView.layer.borderWidth = 1
            blurView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor

            return blurView
        }()

        blurBackgroundView.frame = $0.bounds
        blurBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        $0.addSubview(blurBackgroundView)
        $0.sendSubviewToBack(blurBackgroundView)

        return $0
    }(UIView())
    private(set) var applyButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "apps.ipad.badge.checkmark")
        config.title = "Apply"
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseForegroundColor = .black
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 20)
        var titleAttr = AttributedString("Apply")
        titleAttr.font = .systemFont(ofSize: 20)
        config.attributedTitle = titleAttr

        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 15
        button.backgroundColor = .appBaseColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = .init(width: -4, height: 4)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 4

        let innerShadowLayer = CAShapeLayer()
        let size = CGRect(x: 0, y: 0, width: (UIView.screenWidth - 90) * 0.5, height: 60)
        innerShadowLayer.frame = size
        button.layer.addSublayer(innerShadowLayer)

        let path = UIBezierPath(roundedRect: size.insetBy(dx: -15, dy: -15), cornerRadius: 15)
        let cutout = UIBezierPath(roundedRect: size, cornerRadius: 18).reversing()
        path.append(cutout)

        innerShadowLayer.cornerRadius = 15
        innerShadowLayer.shadowPath = path.cgPath
        innerShadowLayer.masksToBounds = true
        innerShadowLayer.shadowColor = UIColor.black.cgColor
        innerShadowLayer.shadowOffset = .init(width: -7, height: 7)
        innerShadowLayer.shadowOpacity = 0.05
        innerShadowLayer.shadowRadius = 5
        innerShadowLayer.fillRule = .evenOdd
        return button
    }()
    private(set) var gridButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "rectangle.3.offgrid")
        config.title = "Grid"
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseForegroundColor = .black
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 20)
        var titleAttr = AttributedString("Grid")
        titleAttr.font = .systemFont(ofSize: 20)
        config.attributedTitle = titleAttr

        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 15
        button.backgroundColor = .appBaseColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = .init(width: -4, height: 4)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 4

        let innerShadowLayer = CAShapeLayer()
        let size = CGRect(x: 0, y: 0, width: (UIView.screenWidth - 90) * 0.5, height: 60)
        innerShadowLayer.frame = size
        button.layer.addSublayer(innerShadowLayer)

        let path = UIBezierPath(roundedRect: size.insetBy(dx: -15, dy: -15), cornerRadius: 15)
        let cutout = UIBezierPath(roundedRect: size, cornerRadius: 18).reversing()
        path.append(cutout)

        innerShadowLayer.cornerRadius = 15
        innerShadowLayer.shadowPath = path.cgPath
        innerShadowLayer.masksToBounds = true
        innerShadowLayer.shadowColor = UIColor.black.cgColor
        innerShadowLayer.shadowOffset = .init(width: -7, height: 7)
        innerShadowLayer.shadowOpacity = 0.05
        innerShadowLayer.shadowRadius = 5
        innerShadowLayer.fillRule = .evenOdd
        return button
    }()
    private(set) var adjustItemForManualView: UIView = {
        let adjustItemForManualView = UIView()
        adjustItemForManualView.backgroundColor = .appBaseColor

        adjustItemForManualView.alpha = 0
        adjustItemForManualView.isHidden = true
        adjustItemForManualView.isUserInteractionEnabled = true
        adjustItemForManualView.translatesAutoresizingMaskIntoConstraints = false
        return adjustItemForManualView
    }()
    private(set) var blockViewTitleView: UIView = {
        let blockViewTitleView = UIView()
        blockViewTitleView.layer.shadowColor = UIColor.black.cgColor
        blockViewTitleView.layer.shadowOffset = .init(width: -4, height: 4)
        blockViewTitleView.layer.shadowOpacity = 0.1
        blockViewTitleView.layer.shadowRadius = 6
        blockViewTitleView.layer.cornerRadius = 20
        blockViewTitleView.translatesAutoresizingMaskIntoConstraints = false

        let innerShadowLayer = CAShapeLayer()
        let size = CGRect(x: 0, y: 0, width: UIView.screenWidth * 0.8, height: 150)
        innerShadowLayer.frame = size
        blockViewTitleView.layer.addSublayer(innerShadowLayer)

        let path = UIBezierPath(roundedRect: size.insetBy(dx: -15, dy: -15), cornerRadius: 20)
        let cutout = UIBezierPath(roundedRect: size, cornerRadius: 22).reversing()
        path.append(cutout)

        innerShadowLayer.cornerRadius = 20
        innerShadowLayer.shadowPath = path.cgPath
        innerShadowLayer.masksToBounds = true
        innerShadowLayer.shadowColor = UIColor.black.cgColor
        innerShadowLayer.shadowOffset = .init(width: -3, height: 3)
        innerShadowLayer.shadowOpacity = 0.1
        innerShadowLayer.shadowRadius = 6
        innerShadowLayer.fillRule = .evenOdd

        blockViewTitleView.backgroundColor = .appBaseColor

        return blockViewTitleView
    }()
    private(set) var blockViewTitle: UILabel = {
        let blockViewTitle = UILabel()
        blockViewTitle.numberOfLines = 0

        let attributedString = NSMutableAttributedString()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .left

        attributedString.append(
            NSAttributedString(
                string: "Adjust\n",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 29, weight: .bold),
                    .foregroundColor: UIColor.black,
                ]
            )
        )

        let w = ("-" as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 18)]).width
        let c = Int(((UIView.screenWidth * 0.8) - 20) / w)

        attributedString.append(
            NSAttributedString(
                string: String(repeating: "-", count: c) + "\n",
                attributes: [.font: UIFont.systemFont(ofSize: 18), .foregroundColor: UIColor.systemGray3]
            )
        )

        attributedString.append(
            NSAttributedString(
                string: "You can drag the item to move it, or drag the bottom-right corner to resize it.",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 18),
                    .foregroundColor: UIColor.black,
                ]
            )
        )

        attributedString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: attributedString.length)
        )

        blockViewTitle.attributedText = attributedString
        blockViewTitle.translatesAutoresizingMaskIntoConstraints = false
        return blockViewTitle
    }()
    private(set) var selectedItemListScrollView: UIScrollView = {
        let selectedItemListScrollView = UIScrollView()
        selectedItemListScrollView.isHidden = true
        selectedItemListScrollView.alwaysBounceHorizontal = true
        selectedItemListScrollView.alpha = 0
        selectedItemListScrollView.contentInset = .init(top: 0, left: 0, bottom: 0, right: 10)
        selectedItemListScrollView.showsHorizontalScrollIndicator = false
        selectedItemListScrollView.translatesAutoresizingMaskIntoConstraints = false
        return selectedItemListScrollView
    }()
    private(set) var selectedItemListView: UIStackView = {
        let selectedItemListView = UIStackView()
        selectedItemListView.alignment = .center
        selectedItemListView.axis = .horizontal
        selectedItemListView.backgroundColor = .appBaseColor
        selectedItemListView.spacing = 8
        selectedItemListView.translatesAutoresizingMaskIntoConstraints = false
        return selectedItemListView
    }()
    private(set) var moveSelectedItemsToFolderButton: UIButton = {
        var config = UIButton.Configuration.plain()
        var titleAttr = AttributedString("move here")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.titleAlignment = .leading
        config.image = UIImage(systemName: "checkmark.circle")
        config.baseForegroundColor = .systemGreen
        config.cornerStyle = .capsule
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 20)
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)

        titleAttr.font = .systemFont(ofSize: 15)
        config.attributedTitle = titleAttr

        let button = UIButton(configuration: config)
        button.backgroundColor = .systemGreen.withAlphaComponent(0.15)
        button.contentHorizontalAlignment = .leading
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    var dispatcher = PassthroughSubject<MemoHomeViewInput, Never>()
    var viewModel: MemoHomeViewModel
    var subscriptions = Set<AnyCancellable>()
    private var directoryStackDataSource: DirectoryStackDataSource?
    private var privateDirectoryDataSource: DirectoryStackDataSource?
    private let titleAttributedString = NSMutableAttributedString()

    private var sortingOptionwidth: CGFloat = 0
    private var sortByManumalLabelWidth = CGFloat.zero
    private var sortByNameLabelWidth = CGFloat.zero
    private var sortByCreatedateLabelWidth = CGFloat.zero
    private var directoryCollectionViewTopConstraint: NSLayoutConstraint?
    private var directoryCollectionViewBottomConstraint: NSLayoutConstraint?
    private var selectedItemListHeightConstraint: NSLayoutConstraint?

    private(set) var isActiveFileCreatePlusButton: Bool = false
    private var audioControlBarHost: AudioControlBarHostType
    private(set) var directoryPathView = DirectoryPathView()
    private var tabbar = TabBarView()
    private var appSettingView = AppSettingView()
    private(set) var privateDirectoryBlockView = PrivateDirectoryBlockView()
    private var privateDirectoryVisiblityObserver: NSKeyValueObservation?

    init(memoHomeViewModel: MemoHomeViewModel, audioControlBarHost: AudioControlBarHostType) {
        self.viewModel = memoHomeViewModel
        self.audioControlBarHost = audioControlBarHost
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        handleError()
        dispatcher.send(.viewDidLoad)
    }

    func bind() {
        let output = viewModel.subscribe(input: dispatcher.eraseToAnyPublisher())

        output.sink { [weak self] result in
            guard let self else { return }

            switch result {
                case .didFetchMemoData(let directoryStack, let privateDirectoryStack, let manualSortingInfo):
                    directoryStackDataSource = DirectoryStackDataSource(
                        directoryStack: directoryStack,
                        dispatcher: dispatcher,
                        manualSortInfo: manualSortingInfo)

                    privateDirectoryDataSource = DirectoryStackDataSource(
                        directoryStack: privateDirectoryStack,
                        dispatcher: dispatcher,
                        manualSortInfo: manualSortingInfo)

                    let rootDirectoryID = directoryStack.stack.first!.id
                    let sortCriteria = directoryStack.stack.first!.sortBy

                    setupUI()
                    setCurrentSortOptionView(sortBy: sortCriteria)
                    setupConstraints()
                    setupActions(rootDirectoryID)

                case .didUpdateCurrentRootDirectoryInfo(let mainDirectorySize, let dirCount, let pageCount):
                    setMainDirectoryInfo(directoryTotal: dirCount, pageTotal: pageCount, size: mainDirectorySize)

                case .didInsertRowToHomeTable(let collectionCellIndex, let tableCellIndices):
                    insertRowToTable(collectionCellIndex: collectionCellIndex, tableCellIndices: tableCellIndices)

                case .didMoveFileToDormantBox(let removedFileIndex):
                    removeRowToTable(removedFileIndex: removedFileIndex)

                case .didMovePreviousDirectoryPath(let removedIndexList, let sortCriteria):
                    setCurrentSortOptionView(sortBy: sortCriteria)
                    movePreviousDirectoryTappedLabel(removedIndexList: removedIndexList)

                case .didMoveToFollowingDirectory(let directoryName, let directoryID, let sortCriteria):
                    setCurrentSortOptionView(sortBy: sortCriteria)
                    moveToNextDirectory(directoryName: directoryName, directoryID: directoryID)

                case .didNavigateDormantBoxView(let vm):
                    navigationController?.pushViewController(DormantBoxViewController(viewModel: vm), animated: true)

                case .didNavigatePageView(let pageViewModel):
                    let MemoPageViewController = MemoPageViewController(
                        pageViewModel: pageViewModel,
                        audioControlBarHost: audioControlBarHost)
                    navigationController?.pushViewController(MemoPageViewController, animated: true)

                case .didSortDirectoryItems(let sortingResult):
                    sortFileTableRows(sortReulst: sortingResult)

                case .didNavigateSingleTextEditorComponentPageView(let vm, let textComponent, let title):
                    let dispatcher = TextEditorComponentActionDispatcher()
                    let singleTextEditorPageViewController = SingleTextEditorPageViewController()
                    let textEditorComponentUIEventHandler = TextEditorComponentViewEventHandler(
                        contentsView: singleTextEditorPageViewController.textEditorView)

                    dispatcher.bindToViewModel(
                        viewModel: vm,
                        UIEventHandler: textEditorComponentUIEventHandler)

                    singleTextEditorPageViewController.configure(
                        dispatcher: dispatcher, title: title, component: textComponent)
                    navigationController?.pushViewController(singleTextEditorPageViewController, animated: true)

                case .didNavigateSingleTableComponentPageView(let vm, let tableComponent, let pageName):
                    let dispatcher = TableComponentActionDispatcher()
                    let singleTablePageViewController = SingleTablePageViewController()
                    let tableComponentViewEventHandler = TableComponentViewEventHandler(
                        contentsView: singleTablePageViewController.tableComponentContentView)

                    dispatcher.bindToViewModel(viewModel: vm, UIEventHandler: tableComponentViewEventHandler)

                    singleTablePageViewController.configure(
                        dispatcher: dispatcher, component: tableComponent, pageName: pageName)

                    navigationController?.pushViewController(singleTablePageViewController, animated: true)

                case .didNavigateSingleAudioComponentPageView(let vm, let audioComponent, let pageName):
                    let singleAudioViewController =
                        audioControlBarHost.getSingleAudioViewControllerContinuousPlaybackSession(
                            audioComponent: audioComponent, pageName: pageName)
                        ?? {
                            let dispatcher = AudioComponentActionDispatcher()
                            let singleAudioPageViewController = SingleAudioPageViewController(
                                audioControlBarHost: self.audioControlBarHost)
                            let audioComponentUIEventHandler = AudioComponentViewEventHandler(
                                componentView: singleAudioPageViewController.audioComponentContentView,
                                audioControlBarHost: self.audioControlBarHost)

                            dispatcher.bindToViewModel(
                                viewModel: vm,
                                UIEventHandler: audioComponentUIEventHandler)

                            singleAudioPageViewController.configure(
                                dispatcher: dispatcher,
                                audioComponent: audioComponent,
                                pageName: pageName)

                            return singleAudioPageViewController
                        }()

                    navigationController?.pushViewController(singleAudioViewController, animated: true)

                case .didSortManualOrder:
                    if let cell = directoryCollectionView.visibleCells.first as? MemoHomeDirectoryContentCell,
                        let layout = cell.directoryContentTableView.collectionViewLayout as? DirectoryContentsLayout
                    {
                        setCurrentSortOptionView(sortBy: .manual)
                        layout.invalidateLayout()
                    }

                case .didManualAutoGrid:
                    if let cell = directoryCollectionView.visibleCells.first as? MemoHomeDirectoryContentCell {
                        cell.directoryContentTableView.performBatchUpdates(
                            {
                                cell.directoryContentTableView.collectionViewLayout.invalidateLayout()
                            }
                        )
                    }

                case .didCalcFileItemSize(let index, let size):
                    let indexPath = IndexPath(item: index, section: 0)
                    if let cell = directoryCollectionView.visibleCells.first as? MemoHomeDirectoryContentCell,
                        let itemView = cell.directoryContentTableView.cellForItem(at: indexPath) as? FileItemView
                    {
                        let formatter = ByteCountFormatter()
                        formatter.countStyle = .file
                        let totalSize = formatter.string(fromByteCount: size)
                        itemView.setItemSize(size: totalSize)
                    }

                case .didPresentSingleAudioPageInfoView(let index, let audioTotalCount, let duration):
                    let indexPath = IndexPath(item: index, section: 0)
                    if let cell = directoryCollectionView.visibleCells.first as? MemoHomeDirectoryContentCell,
                        let itemView = cell.directoryContentTableView.cellForItem(at: indexPath) as? FileItemView
                    {
                        itemView.setItemSize(size: "calculating...")
                        itemView.setAudioTotalDuration(duration: duration.secondsToTimeString)
                        itemView.setAudioTotalCount(audioTotalCount: "\(audioTotalCount)")
                    }

                case .didPresentDirectoryInfoView(let index, let dirCount, let pageCount):
                    let indexPath = IndexPath(item: index, section: 0)
                    if let cell = directoryCollectionView.visibleCells.first as? MemoHomeDirectoryContentCell,
                        let itemView = cell.directoryContentTableView.cellForItem(at: indexPath) as? FileItemView
                    {
                        itemView.setItemSize(size: "calculating...")
                        itemView.setInnerFileCount(dirCount: "\(dirCount)", pageCount: "\(pageCount)")
                    }

                case .didPresentPageInfoView(let index, let componentCount):
                    let indexPath = IndexPath(item: index, section: 0)
                    if let cell = directoryCollectionView.visibleCells.first as? MemoHomeDirectoryContentCell,
                        let itemView = cell.directoryContentTableView.cellForItem(at: indexPath) as? FileItemView
                    {
                        itemView.setItemSize(size: "calculating...")
                        itemView.setPageInfo(componentCounts: componentCount)
                    }

                case .didGenertingTextComponentSummary(let index, let summary):
                    let indexPath = IndexPath(item: index, section: 0)
                    if let cell = directoryCollectionView.visibleCells.first as? MemoHomeDirectoryContentCell,
                        let itemView = cell.directoryContentTableView.cellForItem(at: indexPath) as? FileItemView
                    {
                        itemView.setTextComponentSummary(summary: summary)
                    }

                case .didGetMostRecentSnapshotDate(let index, let date):
                    let indexPath = IndexPath(item: index, section: 0)
                    if let cell = directoryCollectionView.visibleCells.first as? MemoHomeDirectoryContentCell,
                        let itemView = cell.directoryContentTableView.cellForItem(at: indexPath) as? FileItemView
                    {
                        itemView.setMostRecentSnapshotDate(mostRecentSnpashotDate: date)
                    }

                case .didPresentTableInfo(let index, let columns, let rowCount):
                    let indexPath = IndexPath(item: index, section: 0)
                    if let cell = directoryCollectionView.visibleCells.first as? MemoHomeDirectoryContentCell,
                        let itemView = cell.directoryContentTableView.cellForItem(at: indexPath) as? FileItemView
                    {
                        itemView.setTableInfoLabel(columns: columns.joined(separator: ", "), rowCount: "\(rowCount)")
                    }

                case .didSelectFileItem(let name, let id):
                    selectedItemListHeightConstraint?.constant = 50
                    selectedItemListScrollView.isHidden = false
                    UIView.animate(withDuration: 0.3) {
                        self.selectedItemListScrollView.alpha = 1
                        let item = SelectedItemView(name: name) {
                            self.dispatcher.send(.willRemoveFromSelectedItems(id))
                        }

                        self.selectedItemListView.insertArrangedSubview(
                            item, at: self.selectedItemListView.arrangedSubviews.count - 1)

                        self.directoryCollectionView.collectionViewLayout.invalidateLayout()
                        self.view.layoutIfNeeded()
                        self.selectedItemListScrollView.scrollToTrailing(animated: true)
                    }

                case .didMoveSelectedItems(let indices):
                    for sv in selectedItemListView.arrangedSubviews {
                        if sv is SelectedItemView {
                            selectedItemListView.removeArrangedSubview(sv)
                            sv.removeFromSuperview()
                        }
                    }

                    selectedItemListHeightConstraint?.constant = 0
                    FileItemView.isSelectedSet.removeAll()

                    if let c = self.directoryCollectionView.visibleCells.first as? MemoHomeDirectoryContentCell {
                        for vc in c.directoryContentTableView.visibleCells {
                            (vc as! FileItemView).setSelectedState(false)
                        }
                        c.directoryContentTableView.insertItems(at: indices.map { IndexPath(item: $0, section: 0) })
                    }

                    UIView.animate(withDuration: 0.3) {
                        self.selectedItemListScrollView.alpha = 0
                        self.directoryCollectionView.collectionViewLayout.invalidateLayout()
                        self.view.layoutIfNeeded()
                    } completion: { _ in
                        self.selectedItemListScrollView.isHidden = true
                        self.dispatcher.send(.willManualAutoGrid)
                    }

                case .didRemoveFromSelectedItems(let index, let idx, let itemID):
                    let selectedItem = selectedItemListView.arrangedSubviews[index]

                    UIView.animate(withDuration: 0.3) {
                        selectedItem.alpha = 0
                        selectedItem.isHidden = true
                        if let idx,
                            let c = self.directoryCollectionView.visibleCells.first as? MemoHomeDirectoryContentCell,
                            let fc = c.directoryContentTableView.cellForItem(at: .init(item: idx, section: 0))
                                as? FileItemView
                        {
                            fc.setSelectedState(false)
                        } else {
                            FileItemView.isSelectedSet.remove(itemID)
                        }
                    } completion: { _ in
                        self.selectedItemListView.removeArrangedSubview(selectedItem)
                        selectedItem.removeFromSuperview()
                        if self.selectedItemListView.arrangedSubviews.count == 1 {
                            self.selectedItemListHeightConstraint?.constant = 0
                            UIView.animate(withDuration: 0.3) {
                                self.selectedItemListScrollView.alpha = 0
                                self.directoryCollectionView.collectionViewLayout.invalidateLayout()
                                self.view.layoutIfNeeded()
                            } completion: { _ in
                                self.selectedItemListScrollView.isHidden = true
                            }
                        }
                    }

                case .didCancelAllSelection:
                    for sv in selectedItemListView.arrangedSubviews {
                        if sv is SelectedItemView {
                            selectedItemListView.removeArrangedSubview(sv)
                            sv.removeFromSuperview()
                        }
                    }

                    selectedItemListHeightConstraint?.constant = 0
                    FileItemView.isSelectedSet.removeAll()

                    if let c = self.directoryCollectionView.visibleCells.first as? MemoHomeDirectoryContentCell {
                        for vc in c.directoryContentTableView.visibleCells {
                            (vc as! FileItemView).setSelectedState(false)
                        }
                    }

                    UIView.animate(withDuration: 0.3) {
                        self.selectedItemListScrollView.alpha = 0
                        self.directoryCollectionView.collectionViewLayout.invalidateLayout()
                        self.view.layoutIfNeeded()
                    } completion: { _ in
                        self.selectedItemListScrollView.isHidden = true
                    }

                case .didHidingItem(let index):
                    if let cd = directoryCollectionView.visibleCells.first as? MemoHomeDirectoryContentCell {
                        cd.deleteItem(with: index)
                        dispatcher.send(.willManualAutoGrid)
                        dispatcher.send(.willUpdateCurrentRootDirectoryInfo)
                    }

                case .didPresentSignatureRegisterView:
                    privateDirectoryBlockView.registerSignatureGuideView()
                    privateDirectoryBlockView.dispatcher = dispatcher

                case .didPresentReleaseLockView(let centerPoints):
                    privateDirectoryBlockView.readyToVerifySignature(centers: centerPoints)
                    privateDirectoryBlockView.dispatcher = dispatcher

                case .didTryToUnlockPrivateDirectory(let result):
                    if result {
                        UIView.animate(withDuration: 0.5) {
                            self.privateDirectoryBlockView.alpha = 0
                        } completion: { _ in
                            self.privateDirectoryVisiblityObserver?.invalidate()
                            self.privateDirectoryVisiblityObserver = nil
                            self.audioControlBarHost.setAudioControlBarVisiblityIfActive(nil)
                            self.privateDirectoryBlockView.isHidden = true
                        }
                    } else {
                        UIView.transition(
                            with: privateDirectoryBlockView, duration: 0.3, options: .transitionCrossDissolve
                        ) {
                            self.privateDirectoryBlockView.clear()
                            self.privateDirectoryBlockView.fail()
                        }
                    }

                case .didRegisterSignature(let center):
                    privateDirectoryBlockView.addCenterPoint(center: center)
                    privateDirectoryBlockView.clear()
                    privateDirectoryBlockView.saveSnapshotHistory()

                case .didSuccessRegisterSignature:
                    privateDirectoryBlockView.registerSignatureCompleteView()

                case .didUpdateCurrentDirectoryInfo(let direcotry):
                    setCurrentSortOptionView(sortBy: direcotry.sortBy)
                    directoryPathView.clear()
                    directoryPathView.appendPath(name: direcotry.name) {
                        self.dispatcher.send(.willMovePreviousDirectoryPath(direcotry.id))
                    }
            }
        }
        .store(in: &subscriptions)
    }

    func handleError() {
        viewModel.errorSubscribe()
            .sink { [weak self] errorCase in
                guard let self else { return }

                switch errorCase {
                    case .canNotLoadMemoData:
                        setupUI()
                        setupConstraints()
                        let errorPopupView = ErrorMessagePopupView(error: errorCase) {
                            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                exit(0)
                            }
                        }
                        errorPopupView.show()
                }
            }
            .store(in: &subscriptions)
    }

    func toggleCreateNewItemButtonVisibility() {
        isActiveFileCreatePlusButton.toggle()

        if isActiveFileCreatePlusButton {
            if audioControlBarHost.audioControlBarLayoutState == .expended {
                audioControlBarHost.setAudioControlBarLayoutAsThin()
            }
        }

        let deltaAngle = CGFloat.pi + CGFloat.pi / 4
        let targetAngle = isActiveFileCreatePlusButton ? deltaAngle : deltaAngle + CGFloat.pi / 4

        fileCreatePlusButton.layer.removeAnimation(forKey: "fileCreatePlusButton.spin")

        let springAnimation = CASpringAnimation(keyPath: "transform.rotation.z")
        springAnimation.fromValue = 0
        springAnimation.toValue = targetAngle
        springAnimation.mass = isActiveFileCreatePlusButton ? 0.5 : 0.1
        springAnimation.stiffness = isActiveFileCreatePlusButton ? 100 : 250
        springAnimation.damping = isActiveFileCreatePlusButton ? 7 : 30
        springAnimation.initialVelocity = 0
        springAnimation.duration = springAnimation.settlingDuration

        fileCreatePlusButton.layer.add(springAnimation, forKey: "fileCreatePlusButton.spin")
        fileCreatePlusButton.transform = CGAffineTransform(rotationAngle: targetAngle)

        UIView.springAnimation(0.6) { [weak self] in
            guard let self else { return }

            createFolderButton.alpha = isActiveFileCreatePlusButton ? 1 : 0
            createPageButton.alpha = isActiveFileCreatePlusButton ? 1 : 0

            createFolderButton.frame.origin.y += isActiveFileCreatePlusButton ? -70 : 70
            createPageButton.frame.origin.y += isActiveFileCreatePlusButton ? -140 : 140
        }
    }

    private func setupUI() {
        view.backgroundColor = .appBaseColor
        view.addSubview(appSettingView)

        blockViewTitleView.addSubview(blockViewTitle)
        adjustItemForManualView.addSubview(blockViewTitleView)
        view.addSubview(adjustItemForManualView)
        view.addSubview(tabbar)
        view.addSubview(privateDirectoryBlockView)

        adjustItemForManualView.addSubview(gridButton)
        adjustItemForManualView.addSubview(applyButton)

        titleLabelView.addSubview(titleLabel)
        view.addSubview(titleLabelView)
        view.addSubview(trashBoxButton)

        sortByManumalLabelWidth = sortByManumalLabel.intrinsicContentSize.width
        sortByNameLabelWidth = sortByNameLabel.intrinsicContentSize.width
        sortByCreatedateLabelWidth = sortByCreatedateLabel.intrinsicContentSize.width
        sortingOptionwidth = sortByManumalLabelWidth + sortByNameLabelWidth + sortByCreatedateLabelWidth + 10

        sortingOptionsView.addSubview(sortByManumalLabel)
        sortingOptionsView.addSubview(sortByNameLabel)
        sortingOptionsView.addSubview(sortByCreatedateLabel)

        view.addSubview(sortingOptionsView)
        view.addSubview(directoryPathView)

        selectedItemListScrollView.addSubview(selectedItemListView)
        selectedItemListView.addArrangedSubview(moveSelectedItemsToFolderButton)
        view.addSubview(selectedItemListScrollView)

        view.addSubview(directoryCollectionView)

        directoryCollectionView.dataSource = directoryStackDataSource
        directoryCollectionView.delegate = self
        directoryCollectionView.reloadData()

        view.addSubview(createFolderButton)
        view.addSubview(createPageButton)
        view.addSubview(fileCreatePlusButton)
        view.bringSubviewToFront(tabbar)

        setMainDirectoryInfo(directoryTotal: 0, pageTotal: 0, size: 0)
    }

    private func setupConstraints() {
        directoryCollectionViewTopConstraint =
            directoryCollectionView.topAnchor.constraint(equalTo: selectedItemListScrollView.bottomAnchor, constant: 5)
        directoryCollectionViewBottomConstraint =
            directoryCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        selectedItemListHeightConstraint =
            selectedItemListScrollView.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            titleLabelView.heightAnchor.constraint(equalToConstant: 140),
            titleLabelView.widthAnchor.constraint(equalToConstant: 190),
            titleLabelView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabelView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            titleLabel.topAnchor.constraint(equalTo: titleLabelView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: titleLabelView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: titleLabelView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: titleLabelView.bottomAnchor),

            trashBoxButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            trashBoxButton.widthAnchor.constraint(equalToConstant: 55),
            trashBoxButton.heightAnchor.constraint(equalToConstant: 55),
            trashBoxButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            directoryPathView.topAnchor.constraint(equalTo: titleLabelView.bottomAnchor, constant: 25),
            directoryPathView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            directoryPathView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            directoryPathView.heightAnchor.constraint(equalToConstant: 60),

            sortingOptionsView.topAnchor.constraint(equalTo: directoryPathView.bottomAnchor, constant: 5),
            sortingOptionsView.widthAnchor.constraint(equalToConstant: sortingOptionwidth),
            sortingOptionsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sortingOptionsView.heightAnchor.constraint(equalToConstant: 40),

            sortByManumalLabel.centerYAnchor.constraint(equalTo: sortingOptionsView.centerYAnchor),
            sortByManumalLabel.leadingAnchor.constraint(equalTo: sortingOptionsView.leadingAnchor, constant: 5),

            sortByCreatedateLabel.leadingAnchor.constraint(equalTo: sortByManumalLabel.trailingAnchor),
            sortByCreatedateLabel.centerYAnchor.constraint(equalTo: sortingOptionsView.centerYAnchor),

            sortByNameLabel.centerYAnchor.constraint(equalTo: sortingOptionsView.centerYAnchor),
            sortByNameLabel.leadingAnchor.constraint(equalTo: sortByCreatedateLabel.trailingAnchor),

            selectedItemListView.topAnchor.constraint(equalTo: selectedItemListScrollView.topAnchor),
            selectedItemListView.leadingAnchor.constraint(equalTo: selectedItemListScrollView.leadingAnchor),
            selectedItemListView.trailingAnchor.constraint(equalTo: selectedItemListScrollView.trailingAnchor),
            selectedItemListView.bottomAnchor.constraint(equalTo: selectedItemListScrollView.bottomAnchor),

            selectedItemListScrollView.topAnchor.constraint(equalTo: sortingOptionsView.bottomAnchor, constant: 15),
            selectedItemListHeightConstraint!,
            selectedItemListScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            selectedItemListScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            moveSelectedItemsToFolderButton.heightAnchor.constraint(equalToConstant: 35),
            moveSelectedItemsToFolderButton.widthAnchor.constraint(equalToConstant: 125),

            blockViewTitle.topAnchor.constraint(equalTo: blockViewTitleView.topAnchor, constant: 5),
            blockViewTitle.leadingAnchor.constraint(equalTo: blockViewTitleView.leadingAnchor, constant: 10),
            blockViewTitle.trailingAnchor.constraint(equalTo: blockViewTitleView.trailingAnchor, constant: -10),
            blockViewTitle.bottomAnchor.constraint(equalTo: blockViewTitleView.bottomAnchor, constant: -5),

            blockViewTitleView.topAnchor.constraint(equalTo: adjustItemForManualView.topAnchor, constant: 80),
            blockViewTitleView.centerXAnchor.constraint(equalTo: adjustItemForManualView.centerXAnchor),
            blockViewTitleView.heightAnchor.constraint(equalToConstant: 150),
            blockViewTitleView.widthAnchor.constraint(equalToConstant: UIView.screenWidth * 0.8),

            adjustItemForManualView.topAnchor.constraint(equalTo: view.topAnchor),
            adjustItemForManualView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            adjustItemForManualView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            adjustItemForManualView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            gridButton.leadingAnchor.constraint(equalTo: adjustItemForManualView.leadingAnchor, constant: 30),
            gridButton.widthAnchor.constraint(equalToConstant: (UIView.screenWidth - 90) * 0.5),
            gridButton.heightAnchor.constraint(equalToConstant: 60),
            gridButton.bottomAnchor.constraint(equalTo: adjustItemForManualView.bottomAnchor, constant: -50),

            applyButton.trailingAnchor.constraint(equalTo: adjustItemForManualView.trailingAnchor, constant: -30),
            applyButton.widthAnchor.constraint(equalToConstant: (UIView.screenWidth - 90) * 0.5),
            applyButton.heightAnchor.constraint(equalToConstant: 60),
            applyButton.bottomAnchor.constraint(equalTo: adjustItemForManualView.bottomAnchor, constant: -50),

            directoryCollectionViewTopConstraint!,
            directoryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            directoryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            directoryCollectionViewBottomConstraint!,

            fileCreatePlusButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            fileCreatePlusButton.bottomAnchor.constraint(equalTo: tabbar.topAnchor, constant: -10),
            fileCreatePlusButton.widthAnchor.constraint(equalToConstant: 55),
            fileCreatePlusButton.heightAnchor.constraint(equalToConstant: 55),

            createFolderButton.widthAnchor.constraint(equalToConstant: 55),
            createFolderButton.heightAnchor.constraint(equalToConstant: 55),
            createFolderButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            createFolderButton.bottomAnchor.constraint(equalTo: tabbar.topAnchor, constant: -10),

            createPageButton.widthAnchor.constraint(equalToConstant: 55),
            createPageButton.heightAnchor.constraint(equalToConstant: 55),
            createPageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            createPageButton.bottomAnchor.constraint(equalTo: tabbar.topAnchor, constant: -10),

            appSettingView.topAnchor.constraint(equalTo: view.topAnchor),
            appSettingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            appSettingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            appSettingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            tabbar.heightAnchor.constraint(equalToConstant: 78),
            tabbar.widthAnchor.constraint(equalToConstant: UIView.screenWidth),
            tabbar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            privateDirectoryBlockView.topAnchor.constraint(equalTo: view.topAnchor),
            privateDirectoryBlockView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            privateDirectoryBlockView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            privateDirectoryBlockView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupActions(_ rootDirectoryID: UUID) {
        privateDirectoryVisiblityObserver =
            privateDirectoryBlockView.observe(\.isHidden, options: [.new, .old]) { view, change in
                DispatchQueue.main.async {
                    if let ov = change.oldValue, let nv = change.newValue {
                        if ov != nv {
                            if nv {
                                self.audioControlBarHost.setAudioControlBarVisiblityIfActive(nil)
                            } else {
                                self.audioControlBarHost.setAudioControlBarVisiblityIfActive(!nv)
                            }
                        }
                    }
                }
            }

        fileCreatePlusButton.throttleUIViewTapGesturePublisher(interval: 0)
            .sink { [weak self] _ in
                guard let self else { return }
                toggleCreateNewItemButtonVisibility()
            }
            .store(in: &subscriptions)

        trashBoxButton.throttleTapPublisher()
            .sink { _ in self.dispatcher.send(.willNavigateDormantBoxView) }
            .store(in: &subscriptions)

        createFolderButton.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                toggleCreateNewItemButtonVisibility()

                let popupView = NewDirectoryPopupView(subject: dispatcher)
                popupView.show()
            }
            .store(in: &subscriptions)

        createPageButton.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                toggleCreateNewItemButtonVisibility()

                let popupView = NewPagePopupView(subject: dispatcher)
                popupView.show()
            }
            .store(in: &subscriptions)

        directoryPathView.appendPath(name: "Home") {
            self.dispatcher.send(.willMovePreviousDirectoryPath(rootDirectoryID))
        }

        sortByNameLabel.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                setCurrentSortOptionView(sortBy: .name)
                dispatcher.send(.willSortDirectoryItems(.name))
            }
            .store(in: &subscriptions)

        sortByCreatedateLabel.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                setCurrentSortOptionView(sortBy: .creationDate)
                dispatcher.send(.willSortDirectoryItems(.creationDate))
            }
            .store(in: &subscriptions)

        sortByManumalLabel.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                dispatcher.send(.willCancelAllSelection)
                adjustItemForManualView.isHidden = false

                view.bringSubviewToFront(adjustItemForManualView)

                UIView.animate(withDuration: 0.4) {
                    self.adjustItemForManualView.alpha = 1
                    self.fileCreatePlusButton.alpha = 0
                    self.tabbar.alpha = 0
                    self.audioControlBarHost.setAudioControlBarVisiblityIfActive(nil)
                    self.directoryCollectionView.alpha = 0
                } completion: { [weak self] _ in
                    guard let self else { return }
                    adjustItemForManualView.addSubview(directoryCollectionView)

                    directoryCollectionViewTopConstraint?.isActive = false
                    directoryCollectionViewBottomConstraint?.isActive = false

                    directoryCollectionViewTopConstraint =
                        directoryCollectionView.topAnchor.constraint(
                            equalTo: blockViewTitleView.bottomAnchor, constant: 20)
                    directoryCollectionViewBottomConstraint =
                        directoryCollectionView.bottomAnchor.constraint(
                            equalTo: applyButton.topAnchor, constant: -20)

                    directoryCollectionViewTopConstraint?.isActive = true
                    directoryCollectionViewBottomConstraint?.isActive = true
                    directoryCollectionView.collectionViewLayout.invalidateLayout()
                    view.layoutIfNeeded()

                    UIView.transition(
                        with: directoryCollectionView,
                        duration: 0.4,
                        options: .transitionCrossDissolve
                    ) { [weak self] in
                        guard let self else { return }
                        directoryCollectionView.alpha = 1
                    } completion: { [weak self] _ in
                        guard let self else { return }
                        if let f = directoryCollectionView.visibleCells.first as? MemoHomeDirectoryContentCell {
                            f.directoryContentTableView.allowsSelection = false
                            f.directoryContentDataSource?.isActivePanGesture = true
                            f.directoryContentDataSource?.isActiveLongTapGesture = false
                            f.directoryContentTableView.reloadData()
                        }
                    }
                }
            }
            .store(in: &subscriptions)

        applyButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }

                directoryCollectionViewTopConstraint?.isActive = false
                directoryCollectionViewBottomConstraint?.isActive = false

                view.addSubview(directoryCollectionView)

                directoryCollectionViewTopConstraint =
                    directoryCollectionView.topAnchor
                    .constraint(equalTo: selectedItemListScrollView.bottomAnchor, constant: 5)
                directoryCollectionViewBottomConstraint =
                    directoryCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

                directoryCollectionViewTopConstraint?.isActive = true
                directoryCollectionViewBottomConstraint?.isActive = true

                view.bringSubviewToFront(createPageButton)
                view.bringSubviewToFront(createFolderButton)
                view.bringSubviewToFront(fileCreatePlusButton)
                view.bringSubviewToFront(tabbar)

                UIView.animate(withDuration: 0.3) {
                    self.adjustItemForManualView.alpha = 0
                    self.fileCreatePlusButton.alpha = 1
                    self.tabbar.alpha = 1
                    self.audioControlBarHost.setAudioControlBarVisiblityIfActive(nil)
                    self.directoryCollectionView.collectionViewLayout.invalidateLayout()
                    self.view.layoutIfNeeded()
                } completion: { _ in
                    self.adjustItemForManualView.isHidden = true
                    if let f = self.directoryCollectionView.visibleCells.first as? MemoHomeDirectoryContentCell {
                        f.directoryContentTableView.allowsSelection = true
                        f.directoryContentDataSource?.isActivePanGesture = false
                        f.directoryContentDataSource?.isActiveLongTapGesture = true
                        f.directoryContentTableView.reloadData()
                    }
                }
            }, for: .touchUpInside)

        gridButton.addAction(UIAction { _ in self.dispatcher.send(.willManualAutoGrid) }, for: .touchUpInside)

        moveSelectedItemsToFolderButton.addAction(
            UIAction { _ in
                self.dispatcher.send(.willMoveSelectedItems)
            }, for: .touchUpInside)

        tabbar.homeButton.addAction(
            UIAction { _ in
                self.dispatcher.send(.willMoveTab(.mainDirectory))

                UIView.transition(with: self.view, duration: 0.3, options: .transitionCrossDissolve) { [self] in
                    self.appSettingView.isHidden = true
                    self.appSettingView.alpha = 0
                    self.view.sendSubviewToBack(privateDirectoryBlockView)
                    self.privateDirectoryBlockView.isHidden = true

                    self.directoryCollectionView.dataSource = directoryStackDataSource
                    self.directoryCollectionView.reloadData()
                    self.directoryCollectionView.collectionViewLayout.invalidateLayout()

                    let nsString = titleAttributedString.string as NSString
                    let range = nsString.range(of: "Private")

                    guard range.location != NSNotFound else { return }

                    titleAttributedString.replaceCharacters(
                        in: range,
                        with: NSAttributedString(
                            string: "Home",
                            attributes: [
                                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                                .foregroundColor: UIColor.black,
                            ]
                        )
                    )
                    titleLabel.attributedText = titleAttributedString
                } completion: { _ in
                    self.tabbar.homeButton.isUserInteractionEnabled = false
                    self.tabbar.hideButton.isUserInteractionEnabled = true
                    self.tabbar.settingButton.isUserInteractionEnabled = true
                }

                self.tabbar.changeHome()
            }, for: .touchUpInside)

        tabbar.hideButton.addAction(
            UIAction { _ in
                self.privateDirectoryBlockView.subviews.compactMap { $0 as? UIImageView }.first?.removeFromSuperview()

                if let blurredImage = self.view.window?.fullSnapshotImage()?.blurredByPixcelSize(radius: 22) {
                    let imageView = UIImageView(image: blurredImage)
                    imageView.frame = self.privateDirectoryBlockView.bounds
                    self.privateDirectoryBlockView.addSubview(imageView)
                    self.privateDirectoryBlockView.sendSubviewToBack(imageView)
                }

                self.dispatcher.send(.willMoveTab(.privateDirectory))

                UIView.transition(with: self.view, duration: 0.3, options: .transitionCrossDissolve) { [self] in
                    self.appSettingView.isHidden = true
                    self.appSettingView.alpha = 0
                    self.privateDirectoryBlockView.isHidden = false
                    self.view.sendSubviewToBack(self.appSettingView)
                    self.view.bringSubviewToFront(self.privateDirectoryBlockView)
                    self.view.bringSubviewToFront(self.tabbar)

                    let nsString = self.titleAttributedString.string as NSString
                    let range = nsString.range(of: "Home")

                    if range.location != NSNotFound {
                        self.titleAttributedString.replaceCharacters(
                            in: range,
                            with: NSAttributedString(
                                string: "Private",
                                attributes: [
                                    .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                                    .foregroundColor: UIColor.black,
                                ]
                            )
                        )
                        self.titleLabel.attributedText = self.titleAttributedString
                    }

                    self.directoryCollectionView.dataSource = self.privateDirectoryDataSource
                    self.directoryCollectionView.reloadData()
                    self.directoryCollectionView.collectionViewLayout.invalidateLayout()

                } completion: { _ in
                    self.tabbar.homeButton.isUserInteractionEnabled = true
                    self.tabbar.hideButton.isUserInteractionEnabled = false
                    self.tabbar.settingButton.isUserInteractionEnabled = true
                }
                self.tabbar.changeHide()
            }, for: .touchUpInside)

        tabbar.settingButton.addAction(
            UIAction { _ in
                self.appSettingView.isHidden = false
                self.appSettingView.alpha = 1
                self.dispatcher.send(.willMoveTab(.setting))
                UIView.transition(with: self.view, duration: 0.3, options: .transitionCrossDissolve) { [self] in
                    self.view.sendSubviewToBack(privateDirectoryBlockView)
                    self.privateDirectoryBlockView.isHidden = true
                    self.view.bringSubviewToFront(self.appSettingView)
                    self.view.bringSubviewToFront(self.tabbar)
                } completion: { _ in
                    self.tabbar.homeButton.isUserInteractionEnabled = true
                    self.tabbar.hideButton.isUserInteractionEnabled = true
                    self.tabbar.settingButton.isUserInteractionEnabled = false
                }

                self.tabbar.changeSetting()
            }, for: .touchUpInside)
    }

    private func moveToNextDirectory(directoryName: String, directoryID: UUID) {
        let lastItemIndex = directoryCollectionView.numberOfItems(inSection: .zero)
        let newIndexPath = IndexPath(item: lastItemIndex, section: .zero)

        directoryPathView.appendPath(name: directoryName) {
            self.dispatcher.send(.willMovePreviousDirectoryPath(directoryID))
        }

        directoryCollectionView.insertItems(at: [newIndexPath])
        directoryCollectionView.scrollToItem(at: newIndexPath, at: .right, animated: true)
    }

    private func movePreviousDirectoryTappedLabel(removedIndexList: [Int]) {
        let removeIndexPathList = removedIndexList.map { IndexPath(item: $0, section: 0) }
        directoryCollectionView.deleteItems(at: removeIndexPathList)
    }

    private func insertRowToTable(collectionCellIndex: Int, tableCellIndices: [Int]) {
        let i = IndexPath(item: collectionCellIndex, section: 0)

        if let collectionViewCell = directoryCollectionView.cellForItem(at: i) as? MemoHomeDirectoryContentCell {
            collectionViewCell.insertItem(indices: tableCellIndices)
        }
        dispatcher.send(.willManualAutoGrid)
        dispatcher.send(.willUpdateCurrentRootDirectoryInfo)
    }

    private func removeRowToTable(removedFileIndex: Int) {
        if let currentContent = directoryCollectionView.visibleCells.last as? MemoHomeDirectoryContentCell {
            currentContent.deleteItem(with: removedFileIndex)
            dispatcher.send(.willManualAutoGrid)
            dispatcher.send(.willUpdateCurrentRootDirectoryInfo)
        }
    }

    private func sortFileTableRows(sortReulst: [Int]) {
        guard
            let collectionViewCell = directoryCollectionView.visibleCells.first,
            let cell = collectionViewCell as? MemoHomeDirectoryContentCell
        else { return }

        cell.directoryContentTableView.performBatchUpdates {
            for (i, v) in sortReulst.enumerated() {
                cell.directoryContentTableView.moveItem(
                    at: IndexPath(item: i, section: 0),
                    to: IndexPath(item: v, section: 0))
            }
            cell.directoryContentTableView.collectionViewLayout.invalidateLayout()
        }
    }

    private func setCurrentSortOptionView(sortBy: DirectoryContentsSortCriterias) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveLinear]) { [self] in
            sortByManumalLabel.textColor = sortBy == .manual ? .label : .systemGray4
            sortByNameLabel.textColor = sortBy == .name ? .label : .systemGray4
            sortByCreatedateLabel.textColor = sortBy == .creationDate ? .label : .systemGray4

            sortByManumalLabel.layer.sublayers?.first?.opacity = sortBy == .manual ? 1 : 0
            sortByNameLabel.layer.sublayers?.first?.opacity = sortBy == .name ? 1 : 0
            sortByCreatedateLabel.layer.sublayers?.first?.opacity = sortBy == .creationDate ? 1 : 0
        }
    }

    private func setMainDirectoryInfo(directoryTotal: Int, pageTotal: Int, size: Int64) {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        let totalSize = formatter.string(fromByteCount: size)

        UIView.transition(with: self.titleLabel, duration: 0.4, options: .transitionCrossDissolve) {
            if let li = self.titleAttributedString.string.map({ String($0) }).lastIndex(of: "-") {
                self.titleAttributedString.deleteCharacters(
                    in: NSRange(location: li + 1, length: self.titleAttributedString.length - li - 1))
                [
                    NSAttributedString(
                        string: "directory total : ",
                        attributes: [
                            .font: UIFont.systemFont(ofSize: 17),
                            .foregroundColor: UIColor.systemGray,
                        ]
                    ),
                    NSAttributedString(
                        string: "\(directoryTotal)\n",
                        attributes: [
                            .font: UIFont.systemFont(ofSize: 18),
                            .foregroundColor: UIColor.black,
                        ]
                    ),
                    NSAttributedString(
                        string: "page total : ",
                        attributes: [
                            .font: UIFont.systemFont(ofSize: 17),
                            .foregroundColor: UIColor.systemGray,
                        ]
                    ),
                    NSAttributedString(
                        string: "\(pageTotal)\n",
                        attributes: [
                            .font: UIFont.systemFont(ofSize: 18),
                            .foregroundColor: UIColor.black,
                        ]
                    ),
                    NSAttributedString(
                        string: "total size : ",
                        attributes: [
                            .font: UIFont.systemFont(ofSize: 17),
                            .foregroundColor: UIColor.systemGray,
                        ]
                    ),
                    NSAttributedString(
                        string: "\(totalSize)",
                        attributes: [
                            .font: UIFont.systemFont(ofSize: 18),
                            .foregroundColor: UIColor.black,
                        ]
                    ),
                ]
                .forEach { self.titleAttributedString.append($0) }

                self.titleLabel.attributedText = self.titleAttributedString
            }
        }
    }
}

extension MemoHomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize { collectionView.bounds.size }
}
