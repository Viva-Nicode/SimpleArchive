import Combine
import UIKit

final class TableComponentContentView: UIView, UIScrollViewDelegate {

    final class TableCellTapGestureRecognizer: UITapGestureRecognizer {
        var cellIndex: Int?
        var rowIndex: Int?
        var cellID: UUID?
        var row: TableComponentRowView?
    }

    final class TableColumnTapGestureRecognizer: UITapGestureRecognizer {
        var tappedColumnIndex: Int?
    }

    private(set) var tableComponentToolBarStackView: UIStackView = {
        let tableComponentToolBarStackView = UIStackView()
        tableComponentToolBarStackView.axis = .horizontal
        tableComponentToolBarStackView.alignment = .center
        tableComponentToolBarStackView.distribution = .fill
        tableComponentToolBarStackView.spacing = 13
        tableComponentToolBarStackView.isLayoutMarginsRelativeArrangement = true
        tableComponentToolBarStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0, leading: 10, bottom: 0, trailing: 10)
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
        button.widthAnchor.constraint(equalToConstant: 25).isActive = true
        button.heightAnchor.constraint(equalToConstant: 25).isActive = true
        return button
    }()
    private(set) var rowAddButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        let buttonImage = UIImage(systemName: "text.badge.plus", withConfiguration: config)

        button.setImage(buttonImage, for: .normal)
        button.tintColor = .gray

        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 22.5).isActive = true
        button.heightAnchor.constraint(equalToConstant: 22.5).isActive = true
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
        columnsStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 5, leading: 10, bottom: 5, trailing: 10)

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

    private var dispatcher: TableComponentActionDispatcher?
    private var componentID: UUID!

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

        columnAddButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                dispatcher?.appendColumn(componentID: componentID!)
            }, for: .touchUpInside)

        tableComponentToolBarStackView.addArrangedSubview(rowAddButton)
        rowAddButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                dispatcher?.appendRow(componentID: componentID!)
            }, for: .touchUpInside)

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
            tableComponentToolBarStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableComponentToolBarStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableComponentToolBarStackView.topAnchor.constraint(equalTo: topAnchor),
            tableComponentToolBarStackView.heightAnchor.constraint(equalToConstant: 30),

            columnScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            columnScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            columnScrollView.topAnchor.constraint(equalTo: tableComponentToolBarStackView.bottomAnchor),
            columnScrollView.heightAnchor.constraint(equalToConstant: 38),

            columnContainerView.leadingAnchor.constraint(equalTo: columnScrollView.leadingAnchor),
            columnContainerView.trailingAnchor.constraint(equalTo: columnScrollView.trailingAnchor),
            columnContainerView.heightAnchor.constraint(equalToConstant: 38),

            topBoundary.topAnchor.constraint(equalTo: columnContainerView.topAnchor),
            topBoundary.leadingAnchor.constraint(equalTo: columnContainerView.leadingAnchor),
            topBoundary.trailingAnchor.constraint(equalTo: columnContainerView.trailingAnchor),
            topBoundary.heightAnchor.constraint(equalToConstant: 1.5),

            columnsStackView.topAnchor.constraint(equalTo: topBoundary.bottomAnchor),
            columnsStackView.bottomAnchor.constraint(equalTo: bottomBoundary.topAnchor),
            columnsStackView.leadingAnchor.constraint(equalTo: columnContainerView.leadingAnchor),
            columnsStackView.trailingAnchor.constraint(equalTo: columnContainerView.trailingAnchor),

            bottomBoundary.bottomAnchor.constraint(equalTo: columnContainerView.bottomAnchor),
            bottomBoundary.leadingAnchor.constraint(equalTo: columnContainerView.leadingAnchor),
            bottomBoundary.trailingAnchor.constraint(equalTo: columnContainerView.trailingAnchor),
            bottomBoundary.heightAnchor.constraint(equalToConstant: 1.5),

            rowScrollView.topAnchor.constraint(equalTo: columnScrollView.bottomAnchor),
            rowScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowScrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            rowStackView.topAnchor.constraint(equalTo: rowScrollView.topAnchor),
            rowStackView.leadingAnchor.constraint(equalTo: rowScrollView.leadingAnchor),
            rowStackView.trailingAnchor.constraint(equalTo: rowScrollView.trailingAnchor),
            rowStackView.bottomAnchor.constraint(equalTo: rowScrollView.bottomAnchor),
        ])
    }

    func configure(
        content tableComponentContent: TableComponentContent,
        dispatcher: TableComponentActionDispatcher,
        componentID: UUID
    ) {

        self.dispatcher = dispatcher
        self.componentID = componentID

        columnsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        rowStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        columnWidths = Array(repeating: 0, count: tableComponentContent.columns.count)
        cellWidthConstraints = []

        cellWidthConstraints.append([])

        for (index, column) in tableComponentContent.columns.enumerated() {
            let columnTitleLabel = TableComponentColumnLabel(columnID: column.id)
            columnTitleLabel.text = column.columnTitle
            columnTitleLabel.font = columnTitleFont

            let presentColumnEditPopupViewTapGesture =
                TableColumnTapGestureRecognizer(target: self, action: #selector(presentColumnEditPopupView))
            presentColumnEditPopupViewTapGesture.tappedColumnIndex = index
            columnTitleLabel.addGestureRecognizer(presentColumnEditPopupViewTapGesture)

            let constranint = columnTitleLabel.widthAnchor.constraint(equalToConstant: columnWidths[index])
            cellWidthConstraints[cellWidthConstraints.count - 1].append(constranint)
            constranint.isActive = true
            columnsStackView.addArrangedSubview(columnTitleLabel)
        }

        for row in tableComponentContent.rows {
            createTableComponentRowView(row: row)
        }

        adjustTableContentWidthToFit()
    }

    func configure(content tableComponentContent: TableComponentContent) {

        tableComponentToolBarStackView.removeFromSuperview()
        columnScrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true

        columnsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        rowStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        columnWidths = Array(repeating: 0, count: tableComponentContent.columns.count)
        cellWidthConstraints = []

        cellWidthConstraints.append([])

        for (index, column) in tableComponentContent.columns.enumerated() {
            let columnTitleLabel = TableComponentColumnLabel(columnID: column.id)
            columnTitleLabel.text = column.columnTitle
            columnTitleLabel.font = columnTitleFont

            let constranint = columnTitleLabel.widthAnchor.constraint(equalToConstant: columnWidths[index])
            cellWidthConstraints[cellWidthConstraints.count - 1].append(constranint)
            constranint.isActive = true
            columnsStackView.addArrangedSubview(columnTitleLabel)
        }

        for row in tableComponentContent.rows {
            let tableComponentRowView = TableComponentRowView(rowID: row.id)
            cellWidthConstraints.append([])

            for (cellIndex, cell) in row.cells.enumerated() {
                let cellLabel = TableComponentCellLabel(cellValue: cell.value)
                cellLabel.font = cellValueFont

                let constraint = cellLabel.widthAnchor.constraint(equalToConstant: columnWidths[cellIndex])
                cellWidthConstraints[cellWidthConstraints.count - 1].append(constraint)
                constraint.isActive = true

                tableComponentRowView.addArrangedSubLabel(with: cellLabel)
            }

            rowStackView.addArrangedSubview(tableComponentRowView)
        }

        adjustTableContentWidthToFit()
    }

    private func createTableComponentRowView(row: TableComponentRow) {
        let tableComponentRowView = TableComponentRowView(rowID: row.id)
        cellWidthConstraints.append([])

        for (cellIndex, cell) in row.cells.enumerated() {
            let cellLabel = TableComponentCellLabel(cellValue: cell.value)
            cellLabel.font = cellValueFont

            let constraint = cellLabel.widthAnchor.constraint(equalToConstant: columnWidths[cellIndex])
            cellWidthConstraints[cellWidthConstraints.count - 1].append(constraint)
            constraint.isActive = true

            let singleTap = TableCellTapGestureRecognizer(target: self, action: #selector(presentCellEditPopupView))
            singleTap.cellID = cell.id
            singleTap.cellIndex = cellIndex
            singleTap.row = tableComponentRowView
            singleTap.rowIndex = cellWidthConstraints.count - 1
            singleTap.numberOfTapsRequired = 1

            cellLabel.addGestureRecognizer(singleTap)

            if !cell.value.isEmpty {
                let doubleTap = UITapGestureRecognizer(target: self, action: #selector(copyCellValue))
                doubleTap.numberOfTapsRequired = 2
                cellLabel.addGestureRecognizer(doubleTap)
                singleTap.require(toFail: doubleTap)
            }

            tableComponentRowView.addArrangedSubLabel(with: cellLabel)
        }

        rowStackView.addArrangedSubview(tableComponentRowView)
    }

    private func createTableComponentColumnView(column: TableComponentColumn, cells: [TableComponentCell]) {
        columnWidths.append(.zero)

        let columnTitleLabel = TableComponentColumnLabel(columnID: column.id)
        columnTitleLabel.text = column.columnTitle
        columnTitleLabel.font = columnTitleFont

        let presentColumnEditPopupViewTapGesture =
            TableColumnTapGestureRecognizer(target: self, action: #selector(presentColumnEditPopupView))
        presentColumnEditPopupViewTapGesture.tappedColumnIndex = columnWidths.count - 1
        columnTitleLabel.addGestureRecognizer(presentColumnEditPopupViewTapGesture)

        let constranint = columnTitleLabel.widthAnchor.constraint(equalToConstant: columnWidths[columnWidths.count - 1])
        cellWidthConstraints[0].append(constranint)
        constranint.isActive = true

        columnsStackView.addArrangedSubview(columnTitleLabel)

        for (index, cell) in cells.enumerated() {
            let tableComponentRowView = rowStackView.arrangedSubviews[index] as! TableComponentRowView

            let cellLabel = TableComponentCellLabel(cellValue: cell.value)
            cellLabel.font = cellValueFont

            let constraint = cellLabel.widthAnchor.constraint(equalToConstant: columnWidths[columnWidths.count - 1])
            cellWidthConstraints[index + 1].append(constraint)
            constraint.isActive = true

            let singleTap = TableCellTapGestureRecognizer(target: self, action: #selector(presentCellEditPopupView))
            singleTap.cellID = cell.id
            singleTap.cellIndex = columnWidths.count - 1
            singleTap.row = tableComponentRowView
            singleTap.rowIndex = index + 1
            singleTap.numberOfTapsRequired = 1

            cellLabel.addGestureRecognizer(singleTap)

            tableComponentRowView.addArrangedSubLabel(with: cellLabel)
        }
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
            cellWidthConstraints.forEach { $0[columnIndex]?.constant = columnWidths[columnIndex] }
        }
    }

    func appendRowToRowStackView(row: TableComponentRow) {
        createTableComponentRowView(row: row)
        adjustTableContentWidthToFit()
        layoutIfNeeded()
        rowScrollView.scrollToBottom(animated: true)
    }

    func appendColumnToColumnStackView(_ column: (TableComponentColumn, [TableComponentCell])) {
        createTableComponentColumnView(column: column.0, cells: column.1)
        adjustTableContentWidthToFit()
        layoutIfNeeded()
        rowScrollView.scrollToTrailing(animated: true)
    }

    func removeTableComponentRowView(idx: Int) {
        let view = rowStackView.arrangedSubviews[idx]
        rowStackView.removeArrangedSubview(view)
        view.removeFromSuperview()
        adjustTableContentWidthToFit()
    }

    func applyColumns(columns: [TableComponentColumn]) {

        var moves: [Int?] = []
        var newUIVies = [UIView](repeating: UIView(frame: .zero), count: columns.count)

        for case let columnLabel as TableComponentColumnLabel in columnsStackView.arrangedSubviews {
            moves.append(columns.firstIndex { $0.id == columnLabel.columnID })
        }

        let removeIndexSet = IndexSet(moves.enumerated().filter { i, v in v == nil }.map { i, v in return i })
        columnWidths.remove(atOffsets: removeIndexSet)

        for (i, move) in moves.enumerated() {
            let tableComponentColumnLabel = columnsStackView.arrangedSubviews[i] as! TableComponentColumnLabel
            if let move {
                newUIVies[move] = tableComponentColumnLabel
                tableComponentColumnLabel.text = columns[move].columnTitle
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

            views.forEach { tableComponentRowView.addArrangedSubLabel(with: $0 as! TableComponentCellLabel) }
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

        adjustTableContentWidthToFit()
        //  2차원 DP를 이용해서 O(n)으로 푸는방법 있을거같은데
    }

    func updateUILabelText(rowIndex: Int, cellIndex: Int, with newCellValue: String) {
        let tableComponentRowView = rowStackView.arrangedSubviews[rowIndex] as! TableComponentRowView
        let cellLabel = tableComponentRowView[cellIndex]

        cellLabel.setLabelText(newCellValue)

        if newCellValue.isEmpty {
            let doubleTap = cellLabel.gestureRecognizers?
                .filter { type(of: $0) == UITapGestureRecognizer.self }
                .first!

            cellLabel.removeGestureRecognizer(doubleTap!)
        } else {
            let singleTap = cellLabel.gestureRecognizers?
                .filter { type(of: $0) == TableCellTapGestureRecognizer.self }
                .first!

            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(copyCellValue))
            doubleTap.numberOfTapsRequired = 2
            cellLabel.addGestureRecognizer(doubleTap)
            singleTap!.require(toFail: doubleTap)
        }

        adjustTableContentWidthToFit()
    }

    @objc private func presentCellEditPopupView(_ gesture: TableCellTapGestureRecognizer) {
        guard
            let row = gesture.row,
            let index = gesture.cellIndex,
            let id = gesture.cellID,
            let rowIndex = gesture.rowIndex
        else { return }

        let tableComponentCellEditPopupView =
            TableComponentCellEditPopupView(
                columnTitles: columnsStackView.arrangedSubviews.map { ($0 as! UILabel).text! },
                cellValues: row.cellValues,
                cellIndex: index,
                rowIndex: rowIndex
            )

        editCellPopupViewconfirmButtonStore = tableComponentCellEditPopupView
            .confirmButtonPublisher
            .sink { [weak self] newCellValue in
                guard let self else { return }
                dispatcher?.editCellValue(componentID: componentID!, cellID: id, newValue: newCellValue)
            }

        editCellPopupViewRemoveRowButtonStore = tableComponentCellEditPopupView
            .removeRowButtonPublisher
            .sink { [weak self] _ in
                guard let self else { return }
//                pageInputActionSubject?.send(.removeTableComponentRow(componentID!, row.rowID))
//                singleTableActionSubject?.send(.willRemoveTableComponentRow(row.rowID))
                dispatcher?.removeRow(componentID: componentID!, rowID: row.rowID)
            }

        tableComponentCellEditPopupView.show()
    }

    @objc private func presentColumnEditPopupView(_ gesture: TableColumnTapGestureRecognizer) {
        let tappedColumnIndex = gesture.tappedColumnIndex
        dispatcher?.presentColumnEditPopup(componentID: componentID!, columnIndex: tappedColumnIndex!)
    }

    @objc private func copyCellValue(_ gesture: UITapGestureRecognizer) {
        guard let label = gesture.view as? UILabel else { return }
        guard let text = label.text else { return }

        UIPasteboard.general.string = text

        UIView.transition(with: label, duration: 0.4, options: .transitionCrossDissolve) {
            label.textColor = .systemPink

        } completion: { _ in
            UIView.transition(with: label, duration: 0.4, options: .transitionCrossDissolve) {
                label.textColor = .label
            }
        }
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
}
