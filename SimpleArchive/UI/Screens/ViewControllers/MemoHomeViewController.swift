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

        titleLabelView.backgroundColor = UIColor(named: "FixedFileItemBackgroundColor")

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
                    .foregroundColor: UIColor.black,
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

        button.backgroundColor = UIColor(named: "FixedFileItemBackgroundColor")
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = .init(width: -4, height: 4)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 4
        button.layer.masksToBounds = false
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()
    private(set) var rootDirectoryLable: UIStackView = {
        let directoryPathLabel = MemoHomeDirectoryNameLabel(name: "Home")
        directoryPathLabel.setHomePathLabel()
        return directoryPathLabel
    }()
    private(set) var directoryPathView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    private(set) var directoryPathStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 5
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    private(set) var sortingOptionsView: UIView = {
        let sortingOptionsView = UIView()
        sortingOptionsView.backgroundColor = UIColor(named: "FixedFileItemBackgroundColor")
        sortingOptionsView.layer.cornerRadius = 20
        sortingOptionsView.layer.shadowColor = UIColor.gray.cgColor
        sortingOptionsView.layer.shadowOffset = .init(width: -2, height: 2)
        sortingOptionsView.layer.shadowOpacity = 0.2
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
        sortByManumalLabel.backgroundColor = UIColor(named: "FixedFileItemBackgroundColor")
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
        sortByNameLabel.backgroundColor = UIColor(named: "FixedFileItemBackgroundColor")
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
        sortByCreatedateLabel.backgroundColor = UIColor(named: "FixedFileItemBackgroundColor")
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
        button.backgroundColor = UIColor(named: "FixedFileItemBackgroundColor")
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
        button.backgroundColor = UIColor(named: "FixedFileItemBackgroundColor")
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
        adjustItemForManualView.backgroundColor = UIColor(named: "FixedFileItemBackgroundColor")

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

        blockViewTitleView.backgroundColor = UIColor(named: "FixedFileItemBackgroundColor")

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

    var dispatcher = PassthroughSubject<MemoHomeViewInput, Never>()
    var viewModel: MemoHomeViewModel
    var subscriptions = Set<AnyCancellable>()
    private var directoryStackDataSource: DirectoryStackDataSource?
    private let titleAttributedString = NSMutableAttributedString()

    private var optionwid: CGFloat = 0
    private var sortByManumalLabelWidth = CGFloat.zero
    private var sortByNameLabelWidth = CGFloat.zero
    private var sortByCreatedateLabelWidth = CGFloat.zero
    private var directoryCollectionViewTopConstraint: NSLayoutConstraint?
    private var directoryCollectionViewBottomConstraint: NSLayoutConstraint?

    private(set) var isActiveFileCreatePlusButton: Bool = false
    private var audioControlBarHost: AudioControlBarHostType
    private var tabbar = TabBarView()
    private var appSettingView = AppSettingView()
    private var hideItemView = HideItemView()

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
                case .didFetchMemoData(let directoryStack, let manualSortingInfo):
                    directoryStackDataSource = DirectoryStackDataSource(
                        directoryStack: directoryStack,
                        dispatcher: dispatcher,
                        manualSortInfo: manualSortingInfo)
                    let rootDirectoryID = directoryStack.stack.first!.id
                    let sortCriteria = directoryStack.stack.first!.sortBy

                    setupUI()
                    setCurrentSortOptionView(sortBy: sortCriteria)
                    setupConstraints()
                    setupActions(rootDirectoryID)

                case .didCalcMainDirectoryInfo(let mainDirectorySize, let dirCount, let pageCount):
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
        view.backgroundColor = UIColor(named: "FixedFileItemBackgroundColor")
        view.addSubview(appSettingView)
        view.addSubview(hideItemView)

        blockViewTitleView.addSubview(blockViewTitle)
        adjustItemForManualView.addSubview(blockViewTitleView)
        view.addSubview(adjustItemForManualView)
        view.addSubview(tabbar)

        adjustItemForManualView.addSubview(gridButton)
        adjustItemForManualView.addSubview(applyButton)

        titleLabelView.addSubview(titleLabel)
        view.addSubview(titleLabelView)
        view.addSubview(trashBoxButton)

        sortByManumalLabelWidth = sortByManumalLabel.intrinsicContentSize.width
        sortByNameLabelWidth = sortByNameLabel.intrinsicContentSize.width
        sortByCreatedateLabelWidth = sortByCreatedateLabel.intrinsicContentSize.width
        optionwid = sortByManumalLabelWidth + sortByNameLabelWidth + sortByCreatedateLabelWidth + 10

        sortingOptionsView.addSubview(sortByManumalLabel)
        sortingOptionsView.addSubview(sortByNameLabel)
        sortingOptionsView.addSubview(sortByCreatedateLabel)

        view.addSubview(sortingOptionsView)
        directoryPathView.addSubview(directoryPathStackView)
        directoryPathStackView.addArrangedSubview(rootDirectoryLable)

        view.addSubview(directoryPathView)

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
            directoryCollectionView.topAnchor.constraint(equalTo: sortingOptionsView.bottomAnchor, constant: 20)
        directoryCollectionViewBottomConstraint =
            directoryCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

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

            directoryPathView.topAnchor.constraint(equalTo: titleLabelView.bottomAnchor, constant: 15),
            directoryPathView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            directoryPathView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            directoryPathView.heightAnchor.constraint(equalToConstant: 40),

            directoryPathStackView.topAnchor.constraint(equalTo: directoryPathView.topAnchor),
            directoryPathStackView.bottomAnchor.constraint(equalTo: directoryPathView.bottomAnchor),
            directoryPathStackView.leadingAnchor.constraint(equalTo: directoryPathView.leadingAnchor),
            directoryPathStackView.trailingAnchor.constraint(equalTo: directoryPathView.trailingAnchor),

            sortingOptionsView.topAnchor.constraint(equalTo: directoryPathView.bottomAnchor, constant: 5),
            sortingOptionsView.widthAnchor.constraint(equalToConstant: optionwid),
            sortingOptionsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sortingOptionsView.heightAnchor.constraint(equalToConstant: 40),

            sortByManumalLabel.centerYAnchor.constraint(equalTo: sortingOptionsView.centerYAnchor),
            sortByManumalLabel.leadingAnchor.constraint(equalTo: sortingOptionsView.leadingAnchor, constant: 5),

            sortByCreatedateLabel.leadingAnchor.constraint(equalTo: sortByManumalLabel.trailingAnchor),
            sortByCreatedateLabel.centerYAnchor.constraint(equalTo: sortingOptionsView.centerYAnchor),

            sortByNameLabel.centerYAnchor.constraint(equalTo: sortingOptionsView.centerYAnchor),
            sortByNameLabel.leadingAnchor.constraint(equalTo: sortByCreatedateLabel.trailingAnchor),

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

            hideItemView.topAnchor.constraint(equalTo: view.topAnchor),
            hideItemView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hideItemView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hideItemView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            tabbar.heightAnchor.constraint(equalToConstant: 78),
            tabbar.widthAnchor.constraint(equalToConstant: UIView.screenWidth),
            tabbar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupActions(_ rootDirectoryID: UUID) {
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

        rootDirectoryLable.throttleUIViewTapGesturePublisher(interval: 0.5)
            .sink { [weak self] _ in
                guard let self else { return }
                dispatcher.send(.willMovePreviousDirectoryPath(rootDirectoryID))
            }
            .store(in: &subscriptions)

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
                adjustItemForManualView.isHidden = false

                view.bringSubviewToFront(adjustItemForManualView)

                UIView.animate(withDuration: 0.4) {
                    self.adjustItemForManualView.alpha = 1
                    self.fileCreatePlusButton.alpha = 0
                    self.tabbar.alpha = 0
                    self.audioControlBarHost.setAudioControlBarVisiblityIfActive()
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
                    directoryCollectionView.topAnchor.constraint(equalTo: sortingOptionsView.bottomAnchor, constant: 20)
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
                    self.audioControlBarHost.setAudioControlBarVisiblityIfActive()
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

        tabbar.homeButton.addAction(
            UIAction { _ in
                UIView.animate(withDuration: 0.3) {
                    self.appSettingView.alpha = 0
                    self.hideItemView.alpha = 0
                } completion: { _ in
                    self.hideItemView.isHidden = true
                    self.appSettingView.isHidden = true
                }
            }, for: .touchUpInside)

        tabbar.hideButton.addAction(
            UIAction { _ in
                self.view.bringSubviewToFront(self.hideItemView)
                self.view.bringSubviewToFront(self.tabbar)
                self.hideItemView.isHidden = false

                UIView.animate(withDuration: 0.3) {
                    self.hideItemView.alpha = 1
                } completion: { _ in
                    self.appSettingView.isHidden = true
                    self.appSettingView.alpha = 0
                    self.view.sendSubviewToBack(self.appSettingView)
                }
            }, for: .touchUpInside)

        tabbar.settingButton.addAction(
            UIAction { _ in
                self.view.bringSubviewToFront(self.appSettingView)
                self.view.bringSubviewToFront(self.tabbar)
                self.appSettingView.isHidden = false

                UIView.animate(withDuration: 0.3) {
                    self.appSettingView.alpha = 1
                } completion: { _ in
                    self.hideItemView.isHidden = true
                    self.hideItemView.alpha = 0
                    self.view.sendSubviewToBack(self.hideItemView)
                }
            }, for: .touchUpInside)
    }

    private func moveToNextDirectory(directoryName: String, directoryID: UUID) {
        let lastItemIndex = directoryCollectionView.numberOfItems(inSection: .zero)
        let newIndexPath = IndexPath(item: lastItemIndex, section: .zero)
        let directoryPathLable = MemoHomeDirectoryNameLabel(name: directoryName)
        directoryPathLable.setCurrentPathLabel()

        directoryPathLable.throttleUIViewTapGesturePublisher(interval: 0.5)
            .sink { [weak self] _ in
                guard let self else { return }
                dispatcher.send(.willMovePreviousDirectoryPath(directoryID))
            }
            .store(in: &subscriptions)

        if let last = directoryPathStackView.arrangedSubviews.last,
            let directoryPathLabel = last as? MemoHomeDirectoryNameLabel
        {
            directoryPathLabel.setmiddlePathLabel()
        }

        directoryPathStackView.addArrangedSubview(directoryPathLable)

        directoryCollectionView.insertItems(at: [newIndexPath])
        directoryCollectionView.scrollToItem(at: newIndexPath, at: .right, animated: true)
        DispatchQueue.main.async {
            self.directoryPathView.scrollToTrailing(animated: true)
        }
    }

    private func movePreviousDirectoryTappedLabel(removedIndexList: [Int]) {
        for _ in 0..<removedIndexList.count {
            if let last = directoryPathStackView.arrangedSubviews.last {
                directoryPathStackView.removeArrangedSubview(last)
                last.removeFromSuperview()
            }
        }
        if let last = directoryPathStackView.arrangedSubviews.last,
            let directoryPathLabel = last as? MemoHomeDirectoryNameLabel
        {
            directoryPathLabel.setCurrentPathLabel()
        }

        let removeIndexPathList = removedIndexList.map { IndexPath(item: $0, section: 0) }
        directoryCollectionView.deleteItems(at: removeIndexPathList)
    }

    private func insertRowToTable(collectionCellIndex: Int, tableCellIndices: [Int]) {
        let i = IndexPath(item: collectionCellIndex, section: 0)

        if let collectionViewCell = directoryCollectionView.cellForItem(at: i) as? MemoHomeDirectoryContentCell {
            collectionViewCell.insertItem(indices: tableCellIndices)
        }
        dispatcher.send(.willManualAutoGrid)
        dispatcher.send(.willCalcTotalInfo)
    }

    private func removeRowToTable(removedFileIndex: Int) {
        let lastItemIndex = directoryCollectionView.numberOfItems(inSection: .zero)
        let newIndexPath = IndexPath(item: lastItemIndex - 1, section: .zero)

        guard
            let collectionViewCell = directoryCollectionView.cellForItem(at: newIndexPath),
            let cell = collectionViewCell as? MemoHomeDirectoryContentCell
        else { return }
        cell.deleteItem(with: removedFileIndex)

        dispatcher.send(.willManualAutoGrid)
        dispatcher.send(.willCalcTotalInfo)
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
