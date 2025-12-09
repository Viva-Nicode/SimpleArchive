import Combine
import UIKit

final class TableComponentContentView: UIView, UIScrollViewDelegate {

    private(set) var tableComponentToolBarStackView: UIStackView = {
        let tableComponentToolBarStackView = UIStackView()
        tableComponentToolBarStackView.axis = .horizontal
        tableComponentToolBarStackView.alignment = .center
        tableComponentToolBarStackView.distribution = .fill
        tableComponentToolBarStackView.spacing = 13
        tableComponentToolBarStackView.isLayoutMarginsRelativeArrangement = true
        tableComponentToolBarStackView.directionalLayoutMargins = .init(top: 0, leading: 10, bottom: 0, trailing: 10)
        tableComponentToolBarStackView.translatesAutoresizingMaskIntoConstraints = false
        return tableComponentToolBarStackView
    }()
    private(set) var columnAddButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        let image = UIImage(systemName: "widget.small.badge.plus", withConfiguration: config)

        button.setImage(image, for: .normal)
        button.tintColor = .gray
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private(set) var rowAddButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        let buttonImage = UIImage(systemName: "text.badge.plus", withConfiguration: config)

        button.setImage(buttonImage, for: .normal)
        button.tintColor = .gray
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private(set) var columnScrollView: UIScrollView = {
        let columnScrollView = UIScrollView()
        columnScrollView.translatesAutoresizingMaskIntoConstraints = false
        columnScrollView.showsHorizontalScrollIndicator = false
        columnScrollView.showsVerticalScrollIndicator = false
        columnScrollView.isScrollEnabled = false
        return columnScrollView
    }()
    private(set) var columnContainerView: UIView = {
        let columnContainerView = UIView()
        columnContainerView.translatesAutoresizingMaskIntoConstraints = false
        return columnContainerView
    }()
    private(set) var topBoundary: UIView = {
        let topBoundary = UIView()
        topBoundary.backgroundColor = .systemGray5
        topBoundary.translatesAutoresizingMaskIntoConstraints = false
        return topBoundary
    }()
    private(set) var bottomBoundary: UIView = {
        let bottomBoundary = UIView()
        bottomBoundary.backgroundColor = .systemGray5
        bottomBoundary.translatesAutoresizingMaskIntoConstraints = false
        return bottomBoundary
    }()
    private(set) var columnsStackView: UIStackView = {
        let columnsStackView = UIStackView()
        columnsStackView.axis = .horizontal
        columnsStackView.spacing = 8
        columnsStackView.alignment = .center

        columnsStackView.isLayoutMarginsRelativeArrangement = true
        columnsStackView.directionalLayoutMargins = .init(top: 5, leading: 10, bottom: 5, trailing: 10)

        columnsStackView.distribution = .fill
        columnsStackView.translatesAutoresizingMaskIntoConstraints = false
        return columnsStackView
    }()
    private(set) var rowScrollView: UIScrollView = {
        let rowScrollView = UIScrollView()
        rowScrollView.translatesAutoresizingMaskIntoConstraints = false
        rowScrollView.showsHorizontalScrollIndicator = false
        rowScrollView.showsVerticalScrollIndicator = false
        return rowScrollView
    }()
    private(set) var rowStackView: UIStackView = {
        let rowStackView = UIStackView()
        rowStackView.axis = .vertical
        rowStackView.spacing = 4
        rowStackView.alignment = .fill
        rowStackView.distribution = .equalSpacing
        rowStackView.translatesAutoresizingMaskIntoConstraints = false
        return rowStackView
    }()

    private var isSyncing = false
    private var columnWidths: [CGFloat]!
    private var cellWidthConstraints: [[NSLayoutConstraint?]] = []
    private let maximumWidht = UIConstants.tableComponentCellMaximumWidth
    private let columnTitleFont = UIFont.systemFont(ofSize: 17)
    private let cellValueFont = UIFont.systemFont(ofSize: 16, weight: .thin)

    private var editCellPopupViewconfirmButtonStore: AnyCancellable?
    private var editCellPopupViewRemoveRowButtonStore: AnyCancellable?

    // MARK: - Dispath To ViewModel
    private var componentID: UUID!
    private var dispatcher: TableComponentActionDispatcher?

    // MARK: - Minimization
    private var heightConstraints: [(NSLayoutConstraint, CGFloat)] = []
    private var stackViewConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }

    deinit { print("deinit TableComponentContentView") }

    private func setupUI() {
        addSubview(tableComponentToolBarStackView)

        tableComponentToolBarStackView.addArrangedSubview(UIView.spacerView)
        tableComponentToolBarStackView.addArrangedSubview(columnAddButton)
        tableComponentToolBarStackView.addArrangedSubview(rowAddButton)

        columnAddButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                dispatcher?.appendColumn(componentID: componentID!)
            }, for: .touchUpInside)

        rowAddButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                if columnsStackView.arrangedSubviews.isEmpty {
                    dispatcher?.appendColumn(componentID: componentID!)
                }
                dispatcher?.appendRow(componentID: componentID!)
            }, for: .touchUpInside)

        let presentCellEditPopupViewGestureRecognizer =
            UITapGestureRecognizer(target: self, action: #selector(presentCellEditPopupView(_:)))
        presentCellEditPopupViewGestureRecognizer.numberOfTapsRequired = 1
        rowStackView.addGestureRecognizer(presentCellEditPopupViewGestureRecognizer)

        let copyCellValueGestureRecognizer =
            UITapGestureRecognizer(target: self, action: #selector(copyCellValue(_:)))
        copyCellValueGestureRecognizer.numberOfTapsRequired = 2
        rowStackView.addGestureRecognizer(copyCellValueGestureRecognizer)
        presentCellEditPopupViewGestureRecognizer.require(toFail: copyCellValueGestureRecognizer)

        columnContainerView.addSubview(topBoundary)
        columnContainerView.addSubview(columnsStackView)
        columnContainerView.addSubview(bottomBoundary)

        columnScrollView.addSubview(columnContainerView)
        addSubview(columnScrollView)

        rowScrollView.delegate = self
        columnScrollView.delegate = self

        rowScrollView.addSubview(rowStackView)
        addSubview(rowScrollView)
    }

    private func setupConstraints() {

        NSLayoutConstraint.activate([
            tableComponentToolBarStackView.topAnchor.constraint(equalTo: topAnchor),
            tableComponentToolBarStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableComponentToolBarStackView.trailingAnchor.constraint(equalTo: trailingAnchor),

            rowAddButton.widthAnchor.constraint(equalToConstant: 22.5),
            columnAddButton.widthAnchor.constraint(equalToConstant: 25),

            columnScrollView.topAnchor.constraint(equalTo: tableComponentToolBarStackView.bottomAnchor),
            columnScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            columnScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),

            columnContainerView.leadingAnchor.constraint(equalTo: columnScrollView.leadingAnchor),
            columnContainerView.trailingAnchor.constraint(equalTo: columnScrollView.trailingAnchor),

            topBoundary.topAnchor.constraint(equalTo: columnContainerView.topAnchor),
            topBoundary.leadingAnchor.constraint(equalTo: columnContainerView.leadingAnchor),
            topBoundary.trailingAnchor.constraint(equalTo: columnContainerView.trailingAnchor),

            columnsStackView.leadingAnchor.constraint(equalTo: columnContainerView.leadingAnchor),
            columnsStackView.trailingAnchor.constraint(equalTo: columnContainerView.trailingAnchor),
            columnsStackView.centerYAnchor.constraint(equalTo: columnContainerView.centerYAnchor),

            bottomBoundary.bottomAnchor.constraint(equalTo: columnContainerView.bottomAnchor),
            bottomBoundary.leadingAnchor.constraint(equalTo: columnContainerView.leadingAnchor),
            bottomBoundary.trailingAnchor.constraint(equalTo: columnContainerView.trailingAnchor),

            rowScrollView.topAnchor.constraint(equalTo: columnScrollView.bottomAnchor),
            rowScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),

            rowStackView.topAnchor.constraint(equalTo: rowScrollView.topAnchor),
            rowStackView.leadingAnchor.constraint(equalTo: rowScrollView.leadingAnchor),
            rowStackView.trailingAnchor.constraint(equalTo: rowScrollView.trailingAnchor),
        ])
    }

    func prepareForReuse() {
        columnsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        rowStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        cellWidthConstraints = []

        NSLayoutConstraint.deactivate(heightConstraints.map { $0.0 } + stackViewConstraints)
        heightConstraints = []
        stackViewConstraints = []
    }

    // 싱글 & 멀티 페이지 전용
    func configure(
        columns: [TableComponentColumn],
        rows: [(rowID: UUID, cells: [String])],
        dispatcher: TableComponentActionDispatcher,
        isMinimum: Bool,
        componentID: UUID
    ) {
        self.dispatcher = dispatcher
        self.componentID = componentID

        columnWidths = Array(repeating: 0, count: columns.count)
        cellWidthConstraints.append([])

        for (index, column) in columns.enumerated() {
            let columnTitleLabel = TableComponentColumnLabel(columnID: column.id, cellValue: column.title)
            columnTitleLabel.font = columnTitleFont

            let presentColumnEditPopupViewTapGesture =
                TableColumnTapGestureRecognizer(target: self, action: #selector(presentColumnEditPopupView))
            presentColumnEditPopupViewTapGesture.columnID = column.id
            columnTitleLabel.addGestureRecognizer(presentColumnEditPopupViewTapGesture)

            let constranint = columnTitleLabel.widthAnchor.constraint(equalToConstant: columnWidths[index])
            cellWidthConstraints[cellWidthConstraints.count - 1].append(constranint)
            constranint.isActive = true

            columnsStackView.addArrangedSubview(columnTitleLabel)
        }

        for (rowID, cells) in rows {
            let tableComponentRowView = TableComponentRowView(rowID: rowID)
            cellWidthConstraints.append([])

            for (cellIndex, cell) in cells.enumerated() {
                let cellLabel = TableComponentCellLabel(cellValue: cell)
                cellLabel.font = cellValueFont

                let constraint = cellLabel.widthAnchor.constraint(equalToConstant: columnWidths[cellIndex])
                cellWidthConstraints[cellWidthConstraints.count - 1].append(constraint)
                constraint.isActive = true

                tableComponentRowView.addArrangedSubLabel(with: cellLabel)
            }
            rowStackView.addArrangedSubview(tableComponentRowView)
        }

        adjustTableContentWidthToFit()

        heightConstraints = [
            (tableComponentToolBarStackView.heightAnchor.constraint(equalToConstant: isMinimum ? 0 : 30), 30),
            (rowAddButton.heightAnchor.constraint(equalToConstant: isMinimum ? 0 : 22.5), 22.5),
            (columnAddButton.heightAnchor.constraint(equalToConstant: isMinimum ? 0 : 25), 25),
            (columnContainerView.heightAnchor.constraint(equalToConstant: isMinimum ? 0 : 38), 38),
            (topBoundary.heightAnchor.constraint(equalToConstant: isMinimum ? 0 : 1.5), 1.5),
            (bottomBoundary.heightAnchor.constraint(equalToConstant: isMinimum ? 0 : 1.5), 1.5),
            (columnScrollView.heightAnchor.constraint(equalToConstant: isMinimum ? 0 : 38), 38),
        ]

        stackViewConstraints = [
            columnsStackView.topAnchor.constraint(equalTo: topBoundary.bottomAnchor),
            rowScrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            rowStackView.bottomAnchor.constraint(equalTo: rowScrollView.bottomAnchor),
            columnsStackView.bottomAnchor.constraint(equalTo: bottomBoundary.topAnchor),
        ]

        heightConstraints.forEach { $0.0.isActive = true }
        stackViewConstraints.forEach { $0.isActive = !isMinimum }

        tableComponentToolBarStackView.alpha = isMinimum ? 0 : 1
        columnScrollView.alpha = isMinimum ? 0 : 1
        rowScrollView.alpha = isMinimum ? 0 : 1
    }

    // 스냅샷 전용
    func configure(
        columns: [TableComponentColumn],
        rows: [(rowID: UUID, cells: [String])]
    ) {
        tableComponentToolBarStackView.removeFromSuperview()
        columnScrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true

        columnsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        rowStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        columnWidths = Array(repeating: 0, count: columns.count)
        cellWidthConstraints = []

        cellWidthConstraints.append([])

        for (index, column) in columns.enumerated() {
            let columnTitleLabel = TableComponentColumnLabel(columnID: column.id, cellValue: column.title)
            columnTitleLabel.font = columnTitleFont

            let constranint = columnTitleLabel.widthAnchor.constraint(equalToConstant: columnWidths[index])
            cellWidthConstraints[cellWidthConstraints.count - 1].append(constranint)
            constranint.isActive = true
            columnsStackView.addArrangedSubview(columnTitleLabel)
        }

        for (rowID, cells) in rows {
            let tableComponentRowView = TableComponentRowView(rowID: rowID)
            cellWidthConstraints.append([])

            for (cellIndex, cell) in cells.enumerated() {
                let cellLabel = TableComponentCellLabel(cellValue: cell)
                cellLabel.font = cellValueFont

                let constraint = cellLabel.widthAnchor.constraint(equalToConstant: columnWidths[cellIndex])
                cellWidthConstraints[cellWidthConstraints.count - 1].append(constraint)
                constraint.isActive = true

                tableComponentRowView.addArrangedSubLabel(with: cellLabel)
            }

            rowStackView.addArrangedSubview(tableComponentRowView)
        }

        adjustTableContentWidthToFit()

        heightConstraints = [
            (tableComponentToolBarStackView.heightAnchor.constraint(equalToConstant: 30), 30),
            (rowAddButton.heightAnchor.constraint(equalToConstant: 22.5), 22.5),
            (columnAddButton.heightAnchor.constraint(equalToConstant: 25), 25),
            (columnContainerView.heightAnchor.constraint(equalToConstant: 38), 38),
            (topBoundary.heightAnchor.constraint(equalToConstant: 1.5), 1.5),
            (bottomBoundary.heightAnchor.constraint(equalToConstant: 1.5), 1.5),
            (columnScrollView.heightAnchor.constraint(equalToConstant: 38), 38),
        ]

        stackViewConstraints = [
            columnsStackView.topAnchor.constraint(equalTo: topBoundary.bottomAnchor),
            rowScrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            rowStackView.bottomAnchor.constraint(equalTo: rowScrollView.bottomAnchor),
            columnsStackView.bottomAnchor.constraint(equalTo: bottomBoundary.topAnchor),
        ]

        heightConstraints.forEach { $0.0.isActive = true }
        stackViewConstraints.forEach { $0.isActive = true }

        tableComponentToolBarStackView.alpha = 1
        columnScrollView.alpha = 1
        rowScrollView.alpha = 1
    }

    private func adjustTableContentWidthToFit() {
        layoutIfNeeded()

        for columnIndex in 0..<columnsStackView.arrangedSubviews.count {
            var maximumWidth: CGFloat = .zero
            let columnLabel = columnsStackView.arrangedSubviews[columnIndex] as! UILabel
            let labelText = columnLabel.text!
            let width = labelText.size(withAttributes: [.font: columnTitleFont]).width + 16

            maximumWidth = min(max(maximumWidth, width), maximumWidht)

            for case let tableComponentRowView as TableComponentRowView in rowStackView.arrangedSubviews {
                let label = tableComponentRowView[columnIndex]
                let text = label.text! as NSString
                let width = text.size(withAttributes: [.font: cellValueFont]).width + 16

                maximumWidth = min(max(maximumWidth, width), maximumWidht)
            }

            columnWidths[columnIndex] = maximumWidth
        }

        let totalWidth = columnWidths.reduce(0, +)
        let margin = columnsStackView.layoutMargins.left + columnsStackView.layoutMargins.right
        let spacing = CGFloat((columnWidths.count - 1) * 8)
        let tableContentViewWidth = frame.width - margin - spacing

        if totalWidth < tableContentViewWidth {
            let additionalWidthPerColumn = (tableContentViewWidth - totalWidth) / CGFloat(columnWidths.count)
            columnWidths = columnWidths.map { $0 + additionalWidthPerColumn }
        }

        for columnIndex in 0..<columnsStackView.arrangedSubviews.count {
            cellWidthConstraints.forEach { constraints in
                constraints[columnIndex]?.constant = columnWidths[columnIndex]
            }
        }
    }

    func minimizeContentView(_ isMinimum: Bool) {
        if isMinimum {
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self else { return }
                tableComponentToolBarStackView.alpha = 0
                columnScrollView.alpha = 0
                rowScrollView.alpha = 0

                heightConstraints.forEach { $0.0.constant = .zero }
                NSLayoutConstraint.deactivate(stackViewConstraints)
            }
        } else {
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self else { return }

                heightConstraints.forEach { $0.0.constant = $0.1 }
                NSLayoutConstraint.activate(stackViewConstraints)

                tableComponentToolBarStackView.alpha = 1
                columnScrollView.alpha = 1
                rowScrollView.alpha = 1
            }
        }
    }

    func appendEmptyRowToStackView(rowID: UUID) {
        let tableComponentRowView = TableComponentRowView(rowID: rowID)
        cellWidthConstraints.append([])

        for columnIndex in 0..<columnsStackView.arrangedSubviews.count {
            let cellLabel = TableComponentCellLabel(cellValue: "")
            cellLabel.font = cellValueFont

            let constraint = cellLabel.widthAnchor.constraint(equalToConstant: columnWidths[columnIndex])
            cellWidthConstraints[cellWidthConstraints.count - 1].append(constraint)
            constraint.isActive = true

            tableComponentRowView.addArrangedSubLabel(with: cellLabel)
        }

        rowStackView.addArrangedSubview(tableComponentRowView)
        adjustTableContentWidthToFit()
        layoutIfNeeded()
        rowScrollView.scrollToBottom(animated: true)
    }

    func appendEmptyColumnToStackView(column: TableComponentColumn) {
        columnWidths.append(.zero)
        if cellWidthConstraints.isEmpty { cellWidthConstraints.append([]) }

        let columnTitleLabel = TableComponentColumnLabel(columnID: column.id, cellValue: column.title)
        columnTitleLabel.font = columnTitleFont

        let presentColumnEditPopupViewTapGesture =
            TableColumnTapGestureRecognizer(target: self, action: #selector(presentColumnEditPopupView))
        presentColumnEditPopupViewTapGesture.columnID = column.id
        columnTitleLabel.addGestureRecognizer(presentColumnEditPopupViewTapGesture)

        let constranint = columnTitleLabel.widthAnchor.constraint(equalToConstant: columnWidths[columnWidths.count - 1])
        cellWidthConstraints[0].append(constranint)
        constranint.isActive = true

        columnsStackView.addArrangedSubview(columnTitleLabel)

        for rowIndex in 0..<rowStackView.arrangedSubviews.count {
            let tableComponentRowView = rowStackView.arrangedSubviews[rowIndex] as! TableComponentRowView

            let cellLabel = TableComponentCellLabel(cellValue: "")
            cellLabel.font = cellValueFont

            let constraint = cellLabel.widthAnchor.constraint(equalToConstant: columnWidths[columnWidths.count - 1])
            cellWidthConstraints[rowIndex + 1].append(constraint)
            constraint.isActive = true

            tableComponentRowView.addArrangedSubLabel(with: cellLabel)
        }
        adjustTableContentWidthToFit()
        layoutIfNeeded()
        rowScrollView.scrollToTrailing(animated: true)
    }

    func removeTableComponentRowView(idx: Int) {
        let tableComponentRowView = rowStackView.arrangedSubviews[idx]
        rowStackView.removeArrangedSubview(tableComponentRowView)
        tableComponentRowView.removeFromSuperview()

        let constraints = cellWidthConstraints.remove(at: idx + 1)
        NSLayoutConstraint.deactivate(constraints.compactMap { $0 })
        adjustTableContentWidthToFit()
    }

    func applyColumns(columns: [TableComponentColumn]) {

        var moves: [Int?] = []
        var newUIVies = [UIView](repeating: UIView(frame: .zero), count: columns.count)

        for case let columnLabel as TableComponentColumnLabel in columnsStackView.arrangedSubviews {
            moves.append(columns.firstIndex { $0.id == columnLabel.columnID })
        }

        //        move[0] = 3 원래 0번째에있던게 3번으로 갔더라.
        //        move[1] = nil 원래 1번째에있던게 삭제되었다.

        let removeIndexSet = IndexSet(
            moves.enumerated()
                .filter { i, v in v == nil }
                .map { i, v in return i }
        )

        columnWidths.remove(atOffsets: removeIndexSet)

        for (i, move) in moves.enumerated() {
            let tableComponentColumnLabel = columnsStackView.arrangedSubviews[i] as! TableComponentColumnLabel
            if let move {
                newUIVies[move] = tableComponentColumnLabel
                tableComponentColumnLabel.setLabelText(columns[move].title)
            }
        }

        columnsStackView.arrangedSubviews.forEach {
            columnsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        newUIVies.forEach {
            columnsStackView.addArrangedSubview($0)
        }

        for case let tableComponentRowView as TableComponentRowView in rowStackView.arrangedSubviews {
            var views = [UIView](repeating: UIView(frame: .zero), count: columns.count)

            for (i, move) in moves.enumerated() {
                let res = tableComponentRowView.arrangedSubviews[i]
                if let move {
                    views[move] = res
                }
            }

            tableComponentRowView.arrangedSubviews.forEach {
                tableComponentRowView.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }

            views.forEach {
                tableComponentRowView.addArrangedSubLabel(with: $0 as! TableComponentCellLabel)
            }

            if tableComponentRowView.arrangedSubviews.isEmpty {
                rowStackView.removeArrangedSubview(tableComponentRowView)
                tableComponentRowView.removeFromSuperview()
            }
        }

        for rowIndex in 0..<cellWidthConstraints.count {
            var constraints = [NSLayoutConstraint](repeating: NSLayoutConstraint(), count: columns.count)

            for (i, move) in moves.enumerated() {
                let res = cellWidthConstraints[rowIndex][i]

                if let move {
                    constraints[move] = res!
                }
            }
            cellWidthConstraints[rowIndex] = constraints
        }

        cellWidthConstraints = cellWidthConstraints.filter { !$0.isEmpty }

        adjustTableContentWidthToFit()
    }

    func updateUILabelText(rowIndex: Int, cellIndex: Int, with newCellValue: String) {
        let tableComponentRowView = rowStackView.arrangedSubviews[rowIndex] as! TableComponentRowView
        let cellLabel = tableComponentRowView[cellIndex]

        cellLabel.setLabelText(newCellValue)
        adjustTableContentWidthToFit()
    }

    @objc func presentCellEditPopupView(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: rowStackView)

        if let tappedView = rowStackView.hitTest(location, with: nil) {
            if let cellLabel = tappedView as? TableComponentCellLabel {
                let tableComponentRowView = cellLabel.superview as! TableComponentRowView
                let rowStackView = tableComponentRowView.superview as! UIStackView
                let columnIndex = tableComponentRowView.arrangedSubviews.firstIndex(of: cellLabel)!
                let rowIndex = rowStackView.arrangedSubviews.firstIndex(of: tableComponentRowView)!
                let columnID = (columnsStackView.arrangedSubviews[columnIndex] as! TableComponentColumnLabel).columnID

                let tableComponentCellEditPopupView =
                    TableComponentCellEditPopupView(
                        columnTitles: columnsStackView.arrangedSubviews.map { ($0 as! UILabel).text! },
                        cellValues: tableComponentRowView.cellValues,
                        cellIndex: columnIndex,
                        rowIndex: rowIndex
                    )

                editCellPopupViewconfirmButtonStore = tableComponentCellEditPopupView
                    .confirmButtonPublisher
                    .sink { [weak self] newCellValue in
                        guard let self else { return }
                        dispatcher?
                            .editCellValue(
                                componentID: componentID!,
                                columnID: columnID,
                                rowID: tableComponentRowView.rowID,
                                newValue: newCellValue)
                    }

                editCellPopupViewRemoveRowButtonStore = tableComponentCellEditPopupView
                    .removeRowButtonPublisher
                    .sink { [weak self] _ in
                        guard let self else { return }
                        dispatcher?.removeRow(componentID: componentID!, rowID: tableComponentRowView.rowID)
                    }

                tableComponentCellEditPopupView.show()
            }
        }
    }

    @objc func copyCellValue(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: rowStackView)

        if let tappedView = rowStackView.hitTest(location, with: nil) {
            if let cellLabel = tappedView as? TableComponentCellLabel {

                if cellLabel.cellValue.isEmpty { return }

                UIPasteboard.general.string = cellLabel.cellValue

                UIView.transition(with: cellLabel, duration: 0.4, options: .transitionCrossDissolve) {
                    cellLabel.textColor = .systemPink
                } completion: { _ in
                    UIView.transition(with: cellLabel, duration: 0.4, options: .transitionCrossDissolve) {
                        cellLabel.textColor = .label
                    }
                }
            }
        }
    }

    @objc private func presentColumnEditPopupView(_ gesture: TableColumnTapGestureRecognizer) {
        let tappedColumnID = gesture.columnID
        dispatcher?.presentColumnEditPopup(componentID: componentID!, columnID: tappedColumnID!)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isSyncing else { return }
        isSyncing = true

        let xOffset = scrollView.contentOffset.x

        if scrollView == columnScrollView {
            var offset = rowScrollView.contentOffset
            offset.x = xOffset
            rowScrollView.setContentOffset(offset, animated: false)
        } else if scrollView == rowScrollView {
            var offset = columnScrollView.contentOffset
            offset.x = xOffset
            columnScrollView.setContentOffset(offset, animated: false)
        }

        isSyncing = false
    }

    final class TableColumnTapGestureRecognizer: UITapGestureRecognizer {
        var columnID: UUID?
    }
}
