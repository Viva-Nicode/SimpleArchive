import UIKit

final class EditingCellSeparatorView: UIView {

    private(set) var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 4
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalCentering
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 3, leading: 4, bottom: 3, trailing: 4)
        return stackView
    }()

    var pencilImageView: UIImageView = {
        let pencilImageView = UIImageView(image: UIImage(systemName: "pencil.circle"))
        pencilImageView.translatesAutoresizingMaskIntoConstraints = false
        pencilImageView.tintColor = .white
        return pencilImageView
    }()

    var editingLabel: UILabel = {
        let editingLabel = UILabel()
        editingLabel.text = "Editing"
        editingLabel.textColor = .white
        editingLabel.font = UIFont.systemFont(ofSize: 15)
        return editingLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(
            equalToConstant: UIConstants.TableComponentCellEditPopupViewConstants
                .editingSeparatorLineHeight
        )
        .isActive = true
        widthAnchor.constraint(equalToConstant: 80).isActive = true
        backgroundColor = .systemBlue
        layer.cornerRadius = 8

        stackView.addArrangedSubview(pencilImageView)
        stackView.addArrangedSubview(editingLabel)
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),

            pencilImageView.widthAnchor.constraint(equalToConstant: 16),
            pencilImageView.heightAnchor.constraint(equalToConstant: 16),
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
