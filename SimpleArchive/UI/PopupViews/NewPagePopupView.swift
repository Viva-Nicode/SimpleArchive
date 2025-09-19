import Combine
import UIKit

class NewPagePopupView: PopupView {

    private let subject: PassthroughSubject<MemoHomeSubViewInput, Never>
    private var singleComponentCheckBox = CheckboxButton(title: "Single Component")
    private var kindofComponentItems: [ComponentType] = ComponentType.allCases
    private var selectedComponentType: ComponentType?
    private var selectedIndexPath: IndexPath?

    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "Create New Page"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .black
        return titleLabel
    }()
    private let pageNameTextField: RoundedTextField = {
        let pageNameTextField = RoundedTextField()
        pageNameTextField.accessibilityIdentifier = "newPageNameTextField"
        pageNameTextField.attributedPlaceholder = NSAttributedString(
            string: "Page Name",
            attributes: [.foregroundColor: UIColor.systemGray])
        return pageNameTextField
    }()
    private let confirmButton: DynamicBackgrounColordButton = {
        let confirmButton = DynamicBackgrounColordButton()
        confirmButton.accessibilityIdentifier = "newPageConfirmButton"
        confirmButton.setBackgroundColor(.systemBlue, for: .normal)
        confirmButton.setBackgroundColor(.lightGray, for: .disabled)
        confirmButton.backgroundColor = .systemBlue
        confirmButton.tintColor = .white
        confirmButton.isEnabled = false
        confirmButton.layer.cornerRadius = 5
        confirmButton.configuration = .plain()
        confirmButton.configuration?.contentInsets = NSDirectionalEdgeInsets(
            top: 12, leading: 0, bottom: 12, trailing: 0)

        var titleAttr = AttributedString.init("Create")
        titleAttr.font = .systemFont(ofSize: 15, weight: .regular)
        confirmButton.configuration?.attributedTitle = titleAttr

        return confirmButton
    }()
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isHidden = true
        collectionView.backgroundColor = .white
        return collectionView
    }()

    init(subject: PassthroughSubject<MemoHomeSubViewInput, Never>) {
        self.subject = subject
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { print("deinit NewPagePopupView") }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            pageNameTextField.becomeFirstResponder()
        } else {
            pageNameTextField.resignFirstResponder()
        }
    }

    override func popupViewDetailConfigure() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            ComponentItemView.self, forCellWithReuseIdentifier: ComponentItemView.reuseIdentifier)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.heightAnchor.constraint(equalToConstant: 100).isActive = true

        alertContainer.addArrangedSubview(titleLabel)
        alertContainer.addArrangedSubview(pageNameTextField)
        alertContainer.addArrangedSubview(singleComponentCheckBox)
        alertContainer.addArrangedSubview(collectionView)
        alertContainer.addArrangedSubview(confirmButton)

        singleComponentCheckBox.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }

                updateConfirmButton()
                collectionView.isHidden.toggle()

                if !singleComponentCheckBox.isChecked {
                    selectedComponentType = nil
                    if let selectedIndexPath,
                        let item = collectionView.cellForItem(at: selectedIndexPath) as? ComponentItemView
                    {
                        item.toggle()
                    }
                    selectedIndexPath = nil
                }
            }, for: .touchUpInside)

        pageNameTextField.delegate = self

        confirmButton.throttleTapPublisher()
            .sink { _ in
                self.subject.send(
                    .didCreatedNewPage(self.pageNameTextField.text ?? "new Page", self.selectedComponentType))
                self.dismiss()
            }
            .store(in: &subscriptions)
    }

    private func updateConfirmButton() {
        confirmButton.isEnabled =
            !(pageNameTextField.text?.isEmpty ?? true)
            && (!singleComponentCheckBox.isChecked || selectedComponentType != nil)
    }
}

extension NewPagePopupView: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        updateConfirmButton()
    }
}

extension NewPagePopupView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        ComponentType.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let data = kindofComponentItems[indexPath.item]

        let cell =
            collectionView.dequeueReusableCell(
                withReuseIdentifier: ComponentItemView.reuseIdentifier,
                for: indexPath
            ) as! ComponentItemView

        cell.configure(with: data)
        return cell
    }
}

extension NewPagePopupView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if let selectedItem = collectionView.cellForItem(at: indexPath) as? ComponentItemView {
            selectedItem.toggle()

            if selectedIndexPath == indexPath {
                selectedIndexPath = nil
                selectedComponentType = nil

            } else {
                if let selectedIndexPath {
                    if let item = collectionView.cellForItem(at: selectedIndexPath) as? ComponentItemView {
                        item.toggle()
                    }
                }
                selectedComponentType = kindofComponentItems[indexPath.item]
                selectedIndexPath = indexPath
            }
        }

        updateConfirmButton()
    }
}

extension NewPagePopupView: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.frame.width / 3, height: collectionView.frame.width / 3)
    }

    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat { .zero }

    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat { .zero }
}

class ComponentItemView: UICollectionViewCell {

    static let reuseIdentifier = "ComponentItemView"
    var kindOfItemType: ComponentType?

    var itemSymbol = UIImageView()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 5
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentView.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20).isActive = true
        stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20).isActive = true
        stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
        stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true

        itemSymbol.contentMode = .scaleAspectFill
        stackView.addArrangedSubview(itemSymbol)

    }

    func configure(with: ComponentType) {
        itemSymbol.image = UIImage(systemName: with.getSymbolSystemName)
        itemSymbol.tintColor = .systemGray4
    }

    func toggle() {
        if itemSymbol.tintColor == .systemGray4 {
            itemSymbol.tintColor = .systemPink
        } else {
            itemSymbol.tintColor = .systemGray4
        }
    }
}
