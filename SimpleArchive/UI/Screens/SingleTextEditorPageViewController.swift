import Combine
import UIKit

final class SingleTextEditorPageViewController: UIViewController, ViewControllerType, UITextViewDelegate,
    UIScrollViewDelegate, NavigationViewControllerDismissible, ComponentSnapshotViewControllerDelegate
{

    typealias Input = SingleTextEditorPageInput
    typealias ViewModelType = SingleTextEditorPageViewModel

    var input = PassthroughSubject<SingleTextEditorPageInput, Never>()
    var viewModel: SingleTextEditorPageViewModel
    var detailSubject = PassthroughSubject<String, Never>()
    var subscriptions = Set<AnyCancellable>()

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
    private(set) var textEditorView: UITextView = {
        let textEditorView = UITextView()
        textEditorView.autocorrectionType = .no
        textEditorView.spellCheckingType = .no
        textEditorView.autocapitalizationType = .none
        textEditorView.keyboardDismissMode = .onDrag
        textEditorView.textColor = .label
        textEditorView.font = .systemFont(ofSize: 15)
        textEditorView.translatesAutoresizingMaskIntoConstraints = false
        return textEditorView
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

    override func viewDidLoad() {
        bind()
        input.send(.viewDidLoad(detailSubject))
    }

    init(viewModel: SingleTextEditorPageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { print("SingleTextEditorPageViewController deinit") }

    func bind() {
        let output = viewModel.subscribe(input: input.eraseToAnyPublisher())

        output.sink { [weak self] result in
            guard let self else { return }

            switch result {
                case .viewDidLoad(let title, let date, let detail):
                    setupUI(memoTitle: title, createDate: date, detail: detail)
                    setupConstraint()

                case .didTappedSnapshotButton(let vm):
                    let snapshotView = ComponentSnapshotViewController(viewModel: vm)
                    snapshotView.delegate = self
                    navigationController?.pushViewController(snapshotView, animated: true)

                case .didTappedCaptureButton(let detail):

                    UIView.animate(
                        withDuration: 0.25,
                        animations: {
                            self.textEditorView.alpha = 0
                        }
                    ) { _ in
                        self.textEditorView.delegate = nil
                        self.textEditorView.text = detail

                        UIView.animate(withDuration: 0.25) {
                            self.textEditorView.alpha = 1
                        }
                        self.textEditorView.delegate = self
                    }
            }
        }
        .store(in: &subscriptions)
    }

    private func setupUI(memoTitle: String, createDate: Date, detail: String) {
        view.backgroundColor = .systemBackground
        view.addSubview(headerView)
        headerView.addSubview(titleLable)
        headerView.addSubview(createDateLabel)
        headerView.addSubview(captureButton)
        captureButton.throttleTapPublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                let snapshotCapturePopupView = SnapshotCapturePopupView { snapshotDescription in
                    self.input.send(.willCaptureToComponent(snapshotDescription))
                }
                snapshotCapturePopupView.show()
            }
            .store(in: &subscriptions)
        headerView.addSubview(snapshotButton)
        snapshotButton.throttleTapPublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                input.send(.willPresentSnapshotView)
            }
            .store(in: &subscriptions)

        titleLable.text = memoTitle
        createDateLabel.text = createDate.formattedDate

        view.addSubview(textEditorView)
        textEditorView.delegate = self
        textEditorView.text = detail
    }

    private func setupConstraint() {
        headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        headerView.heightAnchor.constraint(equalToConstant: 60).isActive = true

        titleLable.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10).isActive = true
        titleLable.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10).isActive = true

        createDateLabel.topAnchor.constraint(equalTo: titleLable.bottomAnchor, constant: 3).isActive = true
        createDateLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10).isActive = true

        snapshotButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -10).isActive = true
        snapshotButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true

        captureButton.trailingAnchor.constraint(equalTo: snapshotButton.leadingAnchor, constant: -10).isActive = true
        captureButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true

        textEditorView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 10).isActive = true
        textEditorView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        textEditorView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        textEditorView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    func textViewDidChange(_ textView: UITextView) {
        detailSubject.send(textView.text!)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {

        guard
            let userInfo = notification.userInfo,
            let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }

        let keyboardHeight = view.convert(endFrame, from: nil).intersection(view.frame).height

        self.textEditorView.contentInset.bottom = keyboardHeight
        self.textEditorView.verticalScrollIndicatorInsets.bottom = keyboardHeight
    }

    func onDismiss() {
        input.send(.viewWillDisappear)
        subscriptions.removeAll()
    }

    func reloadCellForRestoredComponent() {
        input.send(.willRestoreComponentWithSnapshot)
    }
}
