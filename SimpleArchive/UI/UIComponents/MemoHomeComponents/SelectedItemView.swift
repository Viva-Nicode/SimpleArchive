import UIKit
import Combine

final class SelectedItemView: UIView {
	private var titleLabel: UILabel = {
		let titleLabel = UILabel()
		titleLabel.textColor = .systemBlue
		titleLabel.numberOfLines = 1
		titleLabel.adjustsFontSizeToFitWidth = true
		titleLabel.minimumScaleFactor = 0.8
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		return titleLabel
	}()
	private var xmarkImageView: UIImageView = {
		let imageView = UIImageView()
		imageView.image = UIImage(systemName: "xmark")
		imageView.tintColor = .systemBlue
		imageView.isUserInteractionEnabled = true
		imageView.translatesAutoresizingMaskIntoConstraints = false
		return imageView
	}()
	private var subscription: AnyCancellable?

	init(name: String, _ removeFromSelectedItems: @escaping () -> Void) {
		super.init(frame: .zero)
		titleLabel.text = name
		subscription = xmarkImageView.throttleUIViewTapGesturePublisher()
			.sink { _ in removeFromSelectedItems() }
		setupUI()
		setupConstraints()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setupUI() {
		backgroundColor = .systemBlue.withAlphaComponent(0.15)
		translatesAutoresizingMaskIntoConstraints = false
		layer.cornerRadius = 35 * 0.5
		addSubview(titleLabel)
		addSubview(xmarkImageView)
	}

	private func setupConstraints() {
		NSLayoutConstraint.activate([
			heightAnchor.constraint(equalToConstant: 35),
			widthAnchor.constraint(lessThanOrEqualToConstant: 140),

			titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
			titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),

			xmarkImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
			xmarkImageView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 6),
			xmarkImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
			xmarkImageView.widthAnchor.constraint(equalToConstant: 17),
			xmarkImageView.heightAnchor.constraint(equalToConstant: 20),
		])
	}
}
