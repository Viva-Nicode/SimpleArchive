import Combine
import UIKit

final class FullScreenTableComponentViewController: ComponentFullScreenView<TableComponentContentView> {

    init(tableComponent: TableComponent, tableComponentContentView: TableComponentContentView) {
        super.init(componentContentView: tableComponentContentView)
        super.setupUI()
        super.setupConstraints()
        toolBarView.backgroundColor = UIColor(named: "TableComponentToolbarColor")

        setupData(title: tableComponent.title, date: tableComponent.creationDate)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { print("FullScreenTableComponentViewController deinit") }

    override var toolbarColor: UIColor? {
        UIColor(named: "TableComponentToolbarColor")
    }

    private func setupData(title: String, date: Date) {
        titleLabel.text = title
        creationDateLabel.text = "created at \(date.formattedDate)"

        greenCircleView.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                dismiss(animated: true)
            }
            .store(in: &subscriptions)
    }
}
