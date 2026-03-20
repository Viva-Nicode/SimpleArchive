import Combine
import UIKit

final class SingleTablePageViewController:
    UIViewController,
    UIScrollViewDelegate,
    ManualCaptureHost,
    ContentsReloadableView
{
    private(set) var headerView: UIView = {
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        return headerView
    }()
    private(set) var titleLable: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()
    private(set) var createDateLabel: UILabel = {
        let createDateLabel = UILabel()
        createDateLabel.font = .systemFont(ofSize: 15)
        createDateLabel.translatesAutoresizingMaskIntoConstraints = false
        return createDateLabel
    }()
    private(set) var captureButton: UIButton = {
        let snapshotButton = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 22)
        let snapshowUIImage = UIImage(systemName: "arrow.down.document.fill", withConfiguration: config)
        snapshotButton.setImage(snapshowUIImage, for: .normal)
        snapshotButton.translatesAutoresizingMaskIntoConstraints = false
        return snapshotButton
    }()
    private(set) var snapshotButton: UIButton = {
        let snapshotButton = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 22)
        let snapshowUIImage = UIImage(systemName: "square.3.layers.3d.down.right", withConfiguration: config)
        snapshotButton.setImage(snapshowUIImage, for: .normal)
        snapshotButton.translatesAutoresizingMaskIntoConstraints = false
        return snapshotButton
    }()
    private(set) var tableComponentContentView: TableComponentContentView = {
        let tableComponentContentView = TableComponentContentView()
        tableComponentContentView.backgroundColor = .systemGray6
        tableComponentContentView.translatesAutoresizingMaskIntoConstraints = false
        return tableComponentContentView
    }()

    var subscriptions = Set<AnyCancellable>()
    var snapshotCapturePopupView: SnapshotCapturePopupView?
    private var actionDispatcher: TableComponentActionDispatcher?

    init() {
        super.init(nibName: nil, bundle: nil)
        setupUI()
        setupConstraint()
        setupAction()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(headerView)
        headerView.addSubview(titleLable)
        headerView.addSubview(createDateLabel)
        headerView.addSubview(snapshotButton)
        headerView.addSubview(captureButton)

        view.addSubview(tableComponentContentView)
    }

    private func setupConstraint() {
        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),

            titleLable.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10),
            titleLable.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10),

            createDateLabel.topAnchor.constraint(equalTo: titleLable.bottomAnchor, constant: 3),
            createDateLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10),

            snapshotButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -10),
            snapshotButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            captureButton.trailingAnchor.constraint(equalTo: snapshotButton.leadingAnchor, constant: -10),
            captureButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            tableComponentContentView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 10),
            tableComponentContentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableComponentContentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableComponentContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupAction() {
        snapshotButton
            .throttleTapPublisher(owner: self)
            .sink { $0.actionDispatcher?.navigateComponentSnapshotView() }
            .store(in: &subscriptions)

        captureButton
            .throttleTapPublisher(owner: self)
            .flatMap { weakself -> AnyPublisher<String, Never> in
                let snapshotCapturePopupView = SnapshotCapturePopupView()
                weakself.snapshotCapturePopupView = snapshotCapturePopupView
                snapshotCapturePopupView.show()

                return snapshotCapturePopupView.captureButtonPublisher
            }
            .sink { [weak self] snapshotDescription in
                guard let self else { return }
                actionDispatcher?.captureComponentManual(description: snapshotDescription)
            }
            .store(in: &subscriptions)
    }

    func configure(dispatcher: TableComponentActionDispatcher, component: TableComponent, pageName: String) {
        self.actionDispatcher = dispatcher

        titleLable.text = pageName
        createDateLabel.text = component.creationDate.formattedDate

        tableComponentContentView.configure(
            columns: component.componentContents.columns,
            rows: component.componentContents.cellValues,
            actionDispatcher: dispatcher,
            isMinimum: false)
    }
	
	func reloadUsingRestoredContents(contents: Codable) {
		if let tableContents = contents as? TableComponentContents {
			tableComponentContentView.alpha = 0

			tableComponentContentView = TableComponentContentView()
			tableComponentContentView.alpha = 0
			tableComponentContentView.translatesAutoresizingMaskIntoConstraints = false
			tableComponentContentView.layer.cornerRadius = 10
			tableComponentContentView.layer.maskedCorners = [
				.layerMaxXMaxYCorner, .layerMinXMaxYCorner,
			]
			tableComponentContentView.backgroundColor = .systemGray6

			view.addSubview(tableComponentContentView)

			NSLayoutConstraint.activate([
				tableComponentContentView
					.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 10),
				tableComponentContentView
					.leadingAnchor.constraint(equalTo: view.leadingAnchor),
				tableComponentContentView
					.trailingAnchor.constraint(equalTo: view.trailingAnchor),
				tableComponentContentView
					.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
			])

			tableComponentContentView.configure(
				columns: tableContents.columns,
				rows: tableContents.cellValues,
				actionDispatcher: actionDispatcher!,
				isMinimum: false)

			UIView.animateKeyframes(withDuration: 0.8, delay: 0, options: []) {
				UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.8) {
					self.tableComponentContentView.alpha = 1
				}
			}
		}
	}

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            actionDispatcher?.clearSubscriptions()
            subscriptions.removeAll()
        }
    }
}
