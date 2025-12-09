import Combine
import UIKit

final class TableComponentColumnEditPopupView: PopupView, UITextViewDelegate {

    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "Edit Columns"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .black
        return titleLabel
    }()

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 18
        layout.itemSize = CGSize(width: 80, height: 70)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsets(top: 10, left: 90, bottom: 10, right: 90)

        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(
            ColumnCarouselCollectionCell.self,
            forCellWithReuseIdentifier: ColumnCarouselCollectionCell.reuseIdentifier
        )
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    private(set) var tableComponentColumnTitleTextView: NeumorphicTextView = {
        let tf = NeumorphicTextView()
        return tf
    }()
    private(set) var removeColumnButton: UIButton = {
        let removeColumnButton = UIButton()
        removeColumnButton.setTitle("remove column", for: .normal)
        removeColumnButton.setTitleColor(.systemBlue, for: .normal)
        removeColumnButton.setTitleColor(.gray, for: .disabled)
        removeColumnButton.titleLabel?.font = .systemFont(ofSize: 15)
        return removeColumnButton
    }()

    private(set) var buttonContainerStackView: UIStackView = {
        let buttonContainerStackView = UIStackView()
        buttonContainerStackView.axis = .horizontal
        buttonContainerStackView.spacing = 8
        buttonContainerStackView.alignment = .center
        buttonContainerStackView.distribution = .fillEqually
        return buttonContainerStackView
    }()
    private(set) var confirmButton: UIButton = {
        let confirmButton = UIButton()
        confirmButton.backgroundColor = .systemBlue
        confirmButton.tintColor = .white
        confirmButton.layer.cornerRadius = 5
        confirmButton.configuration = .plain()
        confirmButton.configuration?.contentInsets = NSDirectionalEdgeInsets(
            top: 12, leading: 0, bottom: 12, trailing: 0)

        var titleAttr = AttributedString.init("Save")
        titleAttr.font = .systemFont(ofSize: 15, weight: .regular)
        confirmButton.configuration?.attributedTitle = titleAttr

        return confirmButton
    }()
    private(set) var cancelButton: UIButton = {
        let cancelButton = UIButton()
        cancelButton.backgroundColor = .systemPink
        cancelButton.tintColor = .white
        cancelButton.layer.cornerRadius = 5
        cancelButton.configuration = .plain()
        cancelButton.configuration?.contentInsets = NSDirectionalEdgeInsets(
            top: 12, leading: 0, bottom: 12, trailing: 0)

        var titleAttr = AttributedString.init("Cancel")
        titleAttr.font = .systemFont(ofSize: 15, weight: .regular)
        cancelButton.configuration?.attributedTitle = titleAttr

        return cancelButton
    }()

    var confirmButtonPublisher: AnyPublisher<[TableComponentColumn], Never> {
        confirmButton
            .throttleTapPublisher()
            .map { _ in
                self.dismiss()
                return self.columns
            }
            .eraseToAnyPublisher()
    }

    private(set) var columns: [TableComponentColumn]
    private(set) var tappedColumnIndex: Int

    init(columns: [TableComponentColumn], tappedColumnIndex: Int) {
        self.columns = columns
        self.tappedColumnIndex = tappedColumnIndex
        self.tableComponentColumnTitleTextView.text = columns[tappedColumnIndex].title
        super.init()
    }

    func textViewDidChange(_ textView: UITextView) {
        columns[tappedColumnIndex].title = textView.text!

        if let item =
            collectionView
            .cellForItem(at: .init(item: tappedColumnIndex, section: 0))
            as? ColumnCarouselCollectionCell
        {
            item.setColumnTitle(columnTitle: textView.text!)
        }

        collectionView.scrollToItem(
            at: IndexPath(item: tappedColumnIndex, section: .zero),
            at: .centeredHorizontally,
            animated: true)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            tableComponentColumnTitleTextView.becomeFirstResponder()
        } else {
            tableComponentColumnTitleTextView.resignFirstResponder()
        }
    }

    override func popupViewDetailConfigure() {
        alertContainer.addArrangedSubview(titleLabel)
        alertContainer.addArrangedSubview(collectionView)

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        tableComponentColumnTitleTextView.delegate = self
        collectionView.dragInteractionEnabled = true

        collectionView.heightAnchor.constraint(equalToConstant: 100).isActive = true

        alertContainer.addArrangedSubview(tableComponentColumnTitleTextView)
        tableComponentColumnTitleTextView.heightAnchor.constraint(equalToConstant: 80).isActive = true

        alertContainer.addArrangedSubview(removeColumnButton)
        removeColumnButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                columns.remove(at: tappedColumnIndex)
                collectionView.deleteItems(at: [IndexPath(item: tappedColumnIndex, section: 0)])
                tappedColumnIndex = max(0, min(columns.count - 1, tappedColumnIndex))

                if columns.isEmpty {
                    tableComponentColumnTitleTextView.delegate = nil
                    tableComponentColumnTitleTextView.text = ""
                    tableComponentColumnTitleTextView.isEditable = false
                    removeColumnButton.isEnabled = false
                } else {
                    if let item = collectionView.cellForItem(at: .init(item: tappedColumnIndex, section: 0))
                        as? ColumnCarouselCollectionCell
                    {
                        item.setIsSelected(isSelected: true)
                    }

                    tableComponentColumnTitleTextView.delegate = nil
                    tableComponentColumnTitleTextView.text = columns[tappedColumnIndex].title
                    tableComponentColumnTitleTextView.delegate = self

                    layoutIfNeeded()

                    collectionView.scrollToItem(
                        at: IndexPath(item: tappedColumnIndex, section: .zero),
                        at: .centeredHorizontally,
                        animated: true)
                }
            }, for: .touchUpInside)

        buttonContainerStackView.addArrangedSubview(cancelButton)
        cancelButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                dismiss()
            }, for: .touchUpInside)
        buttonContainerStackView.addArrangedSubview(confirmButton)

        alertContainer.addArrangedSubview(buttonContainerStackView)

        layoutIfNeeded()

        collectionView.scrollToItem(
            at: IndexPath(item: tappedColumnIndex, section: .zero),
            at: .centeredHorizontally,
            animated: true)
    }
}

extension TableComponentColumnEditPopupView: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        columns.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell =
            collectionView.dequeueReusableCell(
                withReuseIdentifier: ColumnCarouselCollectionCell.reuseIdentifier,
                for: indexPath) as! ColumnCarouselCollectionCell

        cell.setIsSelected(isSelected: indexPath.item == tappedColumnIndex)
        cell.setColumnTitle(columnTitle: columns[indexPath.item].title)
        return cell
    }
}

extension TableComponentColumnEditPopupView: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        if let item = collectionView.cellForItem(at: .init(item: tappedColumnIndex, section: 0))
            as? ColumnCarouselCollectionCell
        {
            item.setIsSelected(isSelected: false)
        }
        tappedColumnIndex = indexPath.item
        tableComponentColumnTitleTextView.delegate = nil
        tableComponentColumnTitleTextView.text = columns[tappedColumnIndex].title
        if let item = collectionView.cellForItem(at: indexPath) as? ColumnCarouselCollectionCell {
            item.setIsSelected(isSelected: true)
        }
        tableComponentColumnTitleTextView.delegate = self
    }
}

extension TableComponentColumnEditPopupView: UICollectionViewDragDelegate, UICollectionViewDropDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {
        let model = columns[indexPath.item]
        let itemProvider = NSItemProvider(object: model.title as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = model
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        session.localDragSession != nil
    }

    func collectionView(
        _ collectionView: UICollectionView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    )
        -> UICollectionViewDropProposal
    {
        if session.localDragSession != nil {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        } else {
            return UICollectionViewDropProposal(operation: .cancel)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        performDropWith coordinator: UICollectionViewDropCoordinator
    ) {
        guard let destIndexPath = coordinator.destinationIndexPath else { return }

        if let item = coordinator.items.first, let sourceIndexPath = item.sourceIndexPath {
            collectionView.performBatchUpdates({
                let editingColumnID = columns[tappedColumnIndex].id

                let item = columns.remove(at: sourceIndexPath.item)
                columns.insert(item, at: destIndexPath.item)

                collectionView.moveItem(at: sourceIndexPath, to: destIndexPath)

                tappedColumnIndex = columns.firstIndex(where: { $0.id == editingColumnID })!
            })

            coordinator.drop(
                item.dragItem, toItemAt: IndexPath(item: max(0, destIndexPath.item), section: destIndexPath.section)
            )
        }
    }
}
