import UIKit

final class HideItemView: UIView {
    private let label: UILabel = {
        let label = UILabel()
        label.text = "hide"
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init() {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        isHidden = true
        alpha = 0
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(named: "FixedFileItemBackgroundColor")
        addSubview(label)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}
