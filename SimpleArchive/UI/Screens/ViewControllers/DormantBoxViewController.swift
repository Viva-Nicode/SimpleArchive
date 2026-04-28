import Combine
import UIKit

final class DormantBoxViewController: UIViewController, ViewControllerType {
    private(set) var titleLabelView: UIView = {
        let titleLabelView = UIView()

        titleLabelView.layer.shadowColor = UIColor.black.cgColor
        titleLabelView.layer.shadowOffset = .init(width: -4, height: 4)
        titleLabelView.layer.shadowOpacity = 0.1
        titleLabelView.layer.shadowRadius = 4
        titleLabelView.layer.cornerRadius = 10
        titleLabelView.translatesAutoresizingMaskIntoConstraints = false

        let innerShadowLayer = CAShapeLayer()
        let size = CGRect(x: 0, y: 0, width: 200, height: 100)
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
                string: "Dormant Box\n",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                    .foregroundColor: UIColor.black,
                ]
            )
        )

        let w = ("-" as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 18)]).width
        let c = Int(180 / w)

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
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()
    private(set) var removedItemTableView: UITableView = {
        let removedItemTableView = UITableView(frame: .zero, style: .plain)
        removedItemTableView.translatesAutoresizingMaskIntoConstraints = false
        removedItemTableView.separatorStyle = .none
        removedItemTableView.backgroundColor = .clear
        removedItemTableView.register(
            RemovedItemView.self,
            forCellReuseIdentifier: RemovedItemView.reuseIdentifier)
        return removedItemTableView
    }()

    var input = PassthroughSubject<DormantBoxViewInput, Never>()
    var viewModel: DormantBoxViewModel
    var subscriptions = Set<AnyCancellable>()
    private var ds: DormantBoxTableViewDataSource?
    private let titleAttributedString = NSMutableAttributedString()
    private var fileInformationView: RemovedFileInformationPopupView?

    init(viewModel: DormantBoxViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        input.send(.viewDidLoad)
    }

    func bind() {
        let output = viewModel.subscribe(input: input.eraseToAnyPublisher())

        output.sink { [weak self] result in
            guard let self else { return }

            switch result {
                case .didfetchMemoData(let dormantBox):
                    ds = DormantBoxTableViewDataSource(dormantBox: dormantBox)
                    removedItemTableView.dataSource = ds
                    removedItemTableView.reloadData()
                    setupUI()
                    setupConstraints()

                case .didCalcDormantBoxDirectoryInfo(let size):
                    let formatter = ByteCountFormatter()
                    formatter.countStyle = .file
                    let totalSize = formatter.string(fromByteCount: size)
                    let totalSizeString = "total size : \(totalSize)"
                    let insertIndex = titleAttributedString.length

                    titleAttributedString.insert(
                        NSAttributedString(
                            string: totalSizeString,
                            attributes: [
                                .font: UIFont.systemFont(ofSize: 16),
                                .foregroundColor: UIColor.black,
                            ]
                        ), at: insertIndex)

                    titleLabel.attributedText = titleAttributedString
					
				case .didRemovePageFromDormantBox(let index):
					removedItemTableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)

                case .showFileInformation(let itemID, let itemName, let itemCreationDate, let c, let s):
                    makePopupView(itemID: itemID, itemName: itemName, itemCreationDate: itemCreationDate, s: s)
                    appendPageInfo(comps: c)
                    presentPopupView()


                case .showSingleAudioPageInformation(let itemID, let itemName, let itemCreationDate, let s, let c):
                    makePopupView(itemID: itemID, itemName: itemName, itemCreationDate: itemCreationDate, s: s)
                    appendAudioComponentInfo(c: c)
                    presentPopupView()

                case .showSingleTextPageInformation(let itemID, let itemName, let itemCreationDate, let s):
                    makePopupView(itemID: itemID, itemName: itemName, itemCreationDate: itemCreationDate, s: s)
                    presentPopupView()

                case .showSingleTablePageInformation(
                    let itemID, let itemName, let itemCreationDate, let s, let columns, let rows):
                    makePopupView(itemID: itemID, itemName: itemName, itemCreationDate: itemCreationDate, s: s)
                    appendTableComponentInfo(columns: columns, rows: rows)
                    presentPopupView()
            }
        }
        .store(in: &subscriptions)
    }

    private func setupUI() {
        view.backgroundColor = UIColor(named: "FixedFileItemBackgroundColor")
        titleLabelView.addSubview(titleLabel)
        view.addSubview(titleLabelView)
        view.addSubview(removedItemTableView)
        removedItemTableView.delegate = self
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabelView.heightAnchor.constraint(equalToConstant: 100),
            titleLabelView.widthAnchor.constraint(equalToConstant: 200),
            titleLabelView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabelView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            titleLabel.topAnchor.constraint(equalTo: titleLabelView.topAnchor, constant: 5),
            titleLabel.leadingAnchor.constraint(equalTo: titleLabelView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: titleLabelView.trailingAnchor, constant: -10),
            titleLabel.bottomAnchor.constraint(equalTo: titleLabelView.bottomAnchor, constant: -5),

            removedItemTableView.topAnchor.constraint(equalTo: titleLabelView.bottomAnchor, constant: 30),
            removedItemTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            removedItemTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            removedItemTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func makePopupView(itemID: UUID, itemName: String, itemCreationDate: Date, s: Int64) {
        fileInformationView = RemovedFileInformationPopupView(
            itemID: itemID, itemName: itemName, itemCreationDate: itemCreationDate)

        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        let totalSize = formatter.string(fromByteCount: s)

        fileInformationView?.attrString
            .append(
                NSAttributedString(
                    string: "size",
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 15, weight: .regular),
                        .foregroundColor: UIColor.systemGray2,
                    ]
                )
            )

        fileInformationView?.attrString
            .append(
                NSAttributedString(
                    string: "\n\(totalSize)",
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 16, weight: .regular),
                        .foregroundColor: UIColor.black,
                    ]
                )
            )
    }

    private func appendTableComponentInfo(columns: [String], rows: Int) {
        fileInformationView?.attrString
            .append(
                NSAttributedString(
                    string: "\n\ncolumns",
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 15, weight: .regular),
                        .foregroundColor: UIColor.systemGray2,
                    ]
                )
            )

        fileInformationView?.attrString
            .append(
                NSAttributedString(
                    string: "\n" + columns.joined(separator: ", "),
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 16, weight: .regular),
                        .foregroundColor: UIColor.black,
                    ]
                )
            )

        fileInformationView?.attrString
            .append(
                NSAttributedString(
                    string: "\n\nrow",
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 15, weight: .regular),
                        .foregroundColor: UIColor.systemGray2,
                    ]
                )
            )

        fileInformationView?.attrString
            .append(
                NSAttributedString(
                    string: "\n\(rows)",
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 16, weight: .regular),
                        .foregroundColor: UIColor.black,
                    ]
                )
            )
    }

    private func appendAudioComponentInfo(c: Int) {
        fileInformationView?.attrString
            .append(
                NSAttributedString(
                    string: "\n\ntracks",
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 15, weight: .regular),
                        .foregroundColor: UIColor.systemGray2,
                    ]
                )
            )

        fileInformationView?.attrString
            .append(
                NSAttributedString(
                    string: "\n\(c)",
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 16, weight: .regular),
                        .foregroundColor: UIColor.black,
                    ]
                )
            )
    }

	private func appendPageInfo(comps: [ComponentType: Int]) {
		fileInformationView?.attrString
			.append(
				NSAttributedString(
					string: "\n\ncomponent",
					attributes: [
						.font: UIFont.systemFont(ofSize: 15, weight: .regular),
						.foregroundColor: UIColor.systemGray2,
					]
				)
			)
		
		fileInformationView?.attrString
			.append(
				NSAttributedString(
					string: "\n" + "\(comps.map { k, v in "\(k.rawValue) : \(v)" }.joined(separator: "\n"))",
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 16, weight: .regular),
                        .foregroundColor: UIColor.black,
                    ]
                )
            )
    }
	
	private func presentPopupView() {
		fileInformationView?.setInfoAttrString()

		fileInformationView?.removeButtonPublisher
			.sink { [weak self] id in
				guard let id else { return }
				self?.input.send(.willRemovePageFromDormantBox(id))
			}
			.store(in: &subscriptions)

		fileInformationView?.show()
	}

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            subscriptions.removeAll()
        }
    }
}

extension DormantBoxViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let restoreFileButton =
            UIContextualAction(style: .destructive, title: "restore") { (_, _, success: @escaping (Bool) -> Void) in
                self.input.send(.restoreFile(indexPath.row))
                tableView.deleteRows(at: [indexPath], with: .fade)
                success(true)
            }

        restoreFileButton.backgroundColor = .systemGreen
        restoreFileButton.image = UIImage(systemName: "arrow.up.trash")
        let config = UISwipeActionsConfiguration(actions: [restoreFileButton])
        config.performsFirstActionWithFullSwipe = false
        return config
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        input.send(.showFileInformation(indexPath.row))
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 50 }
}
