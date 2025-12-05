import Combine
import UIKit

class ComponentSnapshotViewController: UIViewController, ViewControllerType {

    var input = PassthroughSubject<ComponentSnapshotViewModelInput, Never>()
    var viewModel: ComponentSnapshotViewModel
    var subscriptions = Set<AnyCancellable>()
    private var hasRestore: Bool = false
    private var restoreSubject = PassthroughSubject<Bool, Never>()

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
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = false
        collectionView.decelerationRate = .fast

        collectionView.register(
            TextEditorComponentView.self,
            forCellWithReuseIdentifier: TextEditorComponentView.identifierForUseCollectionView
        )

        collectionView.register(
            TableComponentView.self,
            forCellWithReuseIdentifier: TableComponentView.reuseTableComponentIdentifier
        )

        collectionView.isPrefetchingEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
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
        handleError()
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
                case .viewDidLoad(let mostRecentSnapshotMetadata):
                    setupUI(mostRecentSnapshotMetadata)
                    setupConstraints()

                case .hasScrolled(let snapshotMetadata):
                    savingDateLabel.text = snapshotMetadata.makingDate
                    saveModeLabel.text = snapshotMetadata.savemode
                    snapshotDescriptionLabel.text = snapshotMetadata.snapshotDescription

                case .didCompleteRestoreSnapshot:
                    hasRestore = true
                    navigationController?.popViewController(animated: true)

                case .didCompleteRemoveSnapshot(
                    let nextViewedSnapshotMetadata,
                    let removedSnapshotIndex
                ):
                    collectionView.deleteItems(at: [
                        IndexPath(item: removedSnapshotIndex, section: 0)
                    ])
                    if let nextViewedSnapshotMetadata {
                        savingDateLabel.text = nextViewedSnapshotMetadata.makingDate
                        saveModeLabel.text = nextViewedSnapshotMetadata.savemode
                        snapshotDescriptionLabel.text = nextViewedSnapshotMetadata.snapshotDescription
                    } else {
                        savingDateLabel.text = ""
                        saveModeLabel.text = ""
                        snapshotDescriptionLabel.text = ""
                        restoreButton.isEnabled = false
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
                    case .unownedError:
                        let errorPopupView = ErrorMessagePopupView(error: errorCase)
                        errorPopupView.show()

                    case .canNotFoundSnapshot(_):
                        collectionView.reloadData()

                    case .componentIDMismatchError:
                        break
                }
            }
            .store(in: &subscriptions)
    }

    func setupUI(_ mostRecentSnapshotMetadata: SnapshotMetaData?) {
        view.backgroundColor = .systemBackground
        view.addSubview(backgroundView)

        backgroundView.addArrangedSubview(headerView)
        headerView.addSubview(headerTitleLabel)
        headerView.addSubview(backButton)

        let buttonAction = UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }

        backButton.addAction(buttonAction, for: .touchUpInside)

        backgroundView.addArrangedSubview(collectionView)
        collectionView.delegate = viewModel
        collectionView.dataSource = viewModel

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
            input.send(.restoreSnapshot)
        }
        restoreButton.addAction(restoreAction, for: .touchUpInside)

        backgroundView.addArrangedSubview(restoreButtonStackView)
    }

    func setupConstraints() {
        backgroundView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive =
            true

        headerView.heightAnchor.constraint(equalToConstant: 40).isActive = true

        headerTitleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor).isActive = true
        headerTitleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true

        backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20).isActive = true
        backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true

        collectionView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor).isActive = true
        collectionView.heightAnchor.constraint(equalToConstant: UIView.screenWidth).isActive = true

        savingDateIconView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        savingDateIconView.heightAnchor.constraint(equalToConstant: 20).isActive = true

        savingModeIconView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        savingModeIconView.heightAnchor.constraint(equalToConstant: 20).isActive = true

        descriptionIconView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        descriptionIconView.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
}
