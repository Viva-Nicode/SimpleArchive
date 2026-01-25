import Combine
import UIKit

class ComponentSnapshotViewController: UIViewController, ViewControllerType {

    var input = PassthroughSubject<ComponentSnapshotViewModelInput, Never>()
    var viewModel: ComponentSnapshotViewModel
    var subscriptions = Set<AnyCancellable>()

    private var hasRestore: Bool = false
    private var restoreSubject = PassthroughSubject<Bool, Never>()
    private var datasource: ComponentSnapshotCollectionViewDataSource?
    private var snapshotCollectionView: UICollectionView!

    private let backgroundView: UIStackView = {
        let backgroundView = UIStackView()
        backgroundView.backgroundColor = .systemBackground
        backgroundView.axis = .vertical
        backgroundView.spacing = 10
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        return backgroundView
    }()
    private let headerView: UIView = {
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        return headerView
    }()
    private let backButton: UIButton = {
        let backButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20)
        let buttonImage = UIImage(systemName: "chevron.left", withConfiguration: config)
        backButton.setImage(buttonImage, for: .normal)
        backButton.tintColor = .label
        backButton.translatesAutoresizingMaskIntoConstraints = false
        return backButton
    }()
    private let headerTitleLabel: UILabel = {
        let headerTitleLabel = UILabel()
        headerTitleLabel.text = "Snapshot Records"
        headerTitleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        headerTitleLabel.textColor = .label
        headerTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        return headerTitleLabel
    }()

    private let snapshotMetadataStackView: UIStackView = {
        let snapshotMetadataStackView = UIStackView()
        snapshotMetadataStackView.axis = .vertical
        snapshotMetadataStackView.spacing = 8
        snapshotMetadataStackView.alignment = .leading
        snapshotMetadataStackView.isLayoutMarginsRelativeArrangement = true
        snapshotMetadataStackView.layoutMargins = .init(top: 0, left: 20, bottom: 5, right: 20)
        return snapshotMetadataStackView
    }()

    private let savingDateStackView: UIStackView = {
        let savingDateStackView = UIStackView()
        savingDateStackView.axis = .horizontal
        savingDateStackView.alignment = .center
        savingDateStackView.spacing = 8
        savingDateStackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return savingDateStackView
    }()
    private let savingDateIconView: UIView = {
        let savingDateIconImageView = UIImageView()
        savingDateIconImageView.image = UIImage(systemName: "calendar.badge.clock")
        savingDateIconImageView.tintColor = .systemBlue
        savingDateIconImageView.contentMode = .scaleAspectFit
        savingDateIconImageView.translatesAutoresizingMaskIntoConstraints = false
        savingDateIconImageView.setContentHuggingPriority(.defaultHigh, for: .vertical)

        let savingDateIconView = UIView()
        savingDateIconView.addSubview(savingDateIconImageView)
        savingDateIconView.translatesAutoresizingMaskIntoConstraints = false
        savingDateIconView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        savingDateIconImageView.centerYAnchor.constraint(equalTo: savingDateIconView.centerYAnchor).isActive = true
        savingDateIconImageView.centerXAnchor.constraint(equalTo: savingDateIconView.centerXAnchor).isActive = true
        return savingDateIconView
    }()
    let savingDateLabel: UILabel = {
        let savingDateLabel = UILabel()
        savingDateLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        savingDateLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        savingDateLabel.textColor = .label
        return savingDateLabel
    }()

    private let savingModeStackView: UIStackView = {
        let savingDateStackView = UIStackView()
        savingDateStackView.axis = .horizontal
        savingDateStackView.alignment = .center
        savingDateStackView.spacing = 8
        return savingDateStackView
    }()
    private let savingModeIconView: UIView = {
        let savingDateIconImageView = UIImageView()
        savingDateIconImageView.image = UIImage(systemName: "square.and.arrow.down")
        savingDateIconImageView.tintColor = .systemBlue
        savingDateIconImageView.contentMode = .scaleAspectFit
        savingDateIconImageView.translatesAutoresizingMaskIntoConstraints = false

        let savingDateIconView = UIView()
        savingDateIconView.addSubview(savingDateIconImageView)
        savingDateIconView.translatesAutoresizingMaskIntoConstraints = false
        savingDateIconImageView.centerYAnchor.constraint(equalTo: savingDateIconView.centerYAnchor).isActive = true
        savingDateIconImageView.centerXAnchor.constraint(equalTo: savingDateIconView.centerXAnchor).isActive = true
        return savingDateIconView
    }()
    let saveModeLabel: UILabel = {
        let saveModeLabel = UILabel()
        saveModeLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        saveModeLabel.textColor = .label
        return saveModeLabel
    }()

    private let descriptionStackView: UIStackView = {
        let descriptionStackView = UIStackView()
        descriptionStackView.axis = .horizontal
        descriptionStackView.alignment = .top
        descriptionStackView.spacing = 8
        return descriptionStackView
    }()
    private let descriptionIconView: UIView = {
        let descriptionIconImageView = UIImageView()
        descriptionIconImageView.image = UIImage(systemName: "text.page")
        descriptionIconImageView.tintColor = .systemBlue
        descriptionIconImageView.contentMode = .scaleAspectFit
        descriptionIconImageView.translatesAutoresizingMaskIntoConstraints = false

        let descriptionIconView = UIView()
        descriptionIconView.addSubview(descriptionIconImageView)
        descriptionIconView.translatesAutoresizingMaskIntoConstraints = false
        descriptionIconImageView.centerYAnchor.constraint(equalTo: descriptionIconView.centerYAnchor).isActive = true
        descriptionIconImageView.centerXAnchor.constraint(equalTo: descriptionIconView.centerXAnchor).isActive = true
        return descriptionIconView
    }()
    let snapshotDescriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        descriptionLabel.textColor = .label
        descriptionLabel.numberOfLines = 5
        descriptionLabel.lineBreakMode = .byWordWrapping
        return descriptionLabel
    }()

    private let restoreButtonStackView: UIStackView = {
        let restoreButtonStackView = UIStackView()
        restoreButtonStackView.isLayoutMarginsRelativeArrangement = true
        restoreButtonStackView.layoutMargins = .init(top: 5, left: 20, bottom: 5, right: 20)
        restoreButtonStackView.axis = .vertical
        return restoreButtonStackView
    }()
    private let restoreButton: UIButton = {
        var buttonConfiguration = UIButton.Configuration.filled()
        var titleAttr = AttributedString.init("Restore")

        buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 0, bottom: 15, trailing: 0)
        buttonConfiguration.baseBackgroundColor = .systemBlue

        titleAttr.font = .systemFont(ofSize: 17, weight: .regular)
        buttonConfiguration.attributedTitle = titleAttr

        return UIButton(configuration: buttonConfiguration)
    }()

    init(viewModel: ComponentSnapshotViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { print("deinit ComponentSnapshotViewController") }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        input.send(.viewDidLoad)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        restoreSubject.send(hasRestore)
        subscriptions.removeAll()
    }

    var hasRestorePublisher: AnyPublisher<Bool, Never> {
        restoreSubject
            .filter { $0 }
            .eraseToAnyPublisher()
    }

    func bind() {
        let output = viewModel.subscribe(input: input.eraseToAnyPublisher())

        output.sink { [weak self] result in
            guard let self else { return }

            switch result {
                case .viewDidLoad(let com):
                    setupUI(component: com)
                    setupConstraints()

                case .didUpdateSnapshotMetaData(let snapshotMetadata):
                    savingDateLabel.text = snapshotMetadata.makingDate
                    saveModeLabel.text = snapshotMetadata.savemode
                    snapshotDescriptionLabel.text = snapshotMetadata.snapshotDescription

                case .didRestoreSnapshot:
                    hasRestore = true
                    navigationController?.popViewController(animated: true)

                case let .didRemoveSnapshot(nextViewedSnapshotMetadata, removedSnapshotIndex):
                    snapshotCollectionView.deleteItems(at: [
                        IndexPath(item: removedSnapshotIndex, section: 0)
                    ])
                    savingDateLabel.text = nextViewedSnapshotMetadata?.makingDate ?? ""
                    saveModeLabel.text = nextViewedSnapshotMetadata?.savemode ?? ""
                    snapshotDescriptionLabel.text = nextViewedSnapshotMetadata?.snapshotDescription ?? ""
                    restoreButton.isEnabled = nextViewedSnapshotMetadata != nil
            }
        }
        .store(in: &subscriptions)
    }

    private func setupUI(component: any SnapshotRestorablePageComponent) {
        view.backgroundColor = .systemBackground
        view.addSubview(backgroundView)

        backgroundView.addArrangedSubview(headerView)
        headerView.addSubview(headerTitleLabel)
        headerView.addSubview(backButton)

        let buttonAction = UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }

        backButton.addAction(buttonAction, for: .touchUpInside)

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = .init(width: view.bounds.width - 80, height: view.bounds.width - 80)
        layout.sectionInset = .init(top: 20, left: 40, bottom: 0, right: 40)
        layout.minimumLineSpacing = 20

        snapshotCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        snapshotCollectionView.translatesAutoresizingMaskIntoConstraints = false
        snapshotCollectionView.decelerationRate = .fast
        snapshotCollectionView.showsHorizontalScrollIndicator = false

        snapshotCollectionView.register(
            TextEditorComponentView.self,
            forCellWithReuseIdentifier: TextEditorComponentView.identifierForUseCollectionView
        )

        snapshotCollectionView.register(
            TableComponentView.self,
            forCellWithReuseIdentifier: TableComponentView.reuseTableComponentIdentifier
        )

        let factory = PageComponentSnapshotViewFactory(input: input)
        factory.collectionView = snapshotCollectionView
        datasource = ComponentSnapshotCollectionViewDataSource(
            snapshotRestorableComponent: component, factory: factory)

        snapshotCollectionView.dataSource = datasource
        snapshotCollectionView.delegate = self

        backgroundView.addArrangedSubview(snapshotCollectionView)

        let mostRecentSnapshotMetadata = component.snapshots.first?.getSnapshotMetaData()

        savingDateLabel.text = mostRecentSnapshotMetadata?.makingDate ?? ""
        saveModeLabel.text = mostRecentSnapshotMetadata?.savemode ?? ""
        snapshotDescriptionLabel.text = mostRecentSnapshotMetadata?.snapshotDescription ?? ""

        savingDateStackView.addArrangedSubview(savingDateIconView)
        savingDateStackView.addArrangedSubview(savingDateLabel)
        snapshotMetadataStackView.addArrangedSubview(savingDateStackView)

        savingModeStackView.addArrangedSubview(savingModeIconView)
        savingModeStackView.addArrangedSubview(saveModeLabel)
        snapshotMetadataStackView.addArrangedSubview(savingModeStackView)

        descriptionStackView.addArrangedSubview(descriptionIconView)
        descriptionStackView.addArrangedSubview(snapshotDescriptionLabel)
        snapshotMetadataStackView.addArrangedSubview(descriptionStackView)
        snapshotMetadataStackView.addArrangedSubview(UIView.spacerView)

        backgroundView.addArrangedSubview(snapshotMetadataStackView)
        restoreButtonStackView.addArrangedSubview(restoreButton)
        restoreButton.isEnabled = mostRecentSnapshotMetadata != nil

        let restoreAction = UIAction { [weak self] _ in
            guard let self else { return }
            input.send(.willRestoreSnapshot)
        }
        restoreButton.addAction(restoreAction, for: .touchUpInside)

        backgroundView.addArrangedSubview(restoreButtonStackView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            headerView.heightAnchor.constraint(equalToConstant: 40),

            headerTitleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            headerTitleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            snapshotCollectionView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            snapshotCollectionView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            snapshotCollectionView.heightAnchor.constraint(equalToConstant: UIView.screenWidth),

            savingDateIconView.widthAnchor.constraint(equalToConstant: 30),
            savingDateIconView.heightAnchor.constraint(equalToConstant: 20),

            savingModeIconView.widthAnchor.constraint(equalToConstant: 30),
            savingModeIconView.heightAnchor.constraint(equalToConstant: 20),

            descriptionIconView.widthAnchor.constraint(equalToConstant: 30),
            descriptionIconView.heightAnchor.constraint(equalToConstant: 20),
        ])
    }
}

extension ComponentSnapshotViewController: UICollectionViewDelegate {
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        let cellWidthIncludingSpacing = UIView.screenWidth - 60

        // targetContentOff을 이용하여 x좌표가 얼마나 이동했는지 확인
        // 이동한 x좌표 값과 item의 크기를 비교하여 몇 페이징이 될 것인지 값 설정
        var offset = targetContentOffset.pointee
        let index = (offset.x + scrollView.contentInset.left) / cellWidthIncludingSpacing
        var roundedIndex = round(index)

        // scrollView, targetContentOffset의 좌표 값으로 스크롤 방향을 알 수 있다.
        // index를 반올림하여 사용하면 item의 절반 사이즈만큼 스크롤을 해야 페이징이 된다.
        // 스크로로 방향을 체크하여 올림,내림을 사용하면 좀 더 자연스러운 페이징 효과를 낼 수 있다.
        if scrollView.contentOffset.x > targetContentOffset.pointee.x {
            roundedIndex = floor(index)
        } else if scrollView.contentOffset.x < targetContentOffset.pointee.x {
            roundedIndex = ceil(index)
        } else {
            roundedIndex = round(index)
        }

        // 위 코드를 통해 페이징 될 좌표값을 targetContentOffset에 대입하면 된다.
        offset = CGPoint(
            x: roundedIndex * cellWidthIncludingSpacing - scrollView.contentInset.left,
            y: -scrollView.contentInset.top)
        targetContentOffset.pointee = offset

        input.send(.willUpdateSnapshotMetaData(Int(roundedIndex)))
    }
}
