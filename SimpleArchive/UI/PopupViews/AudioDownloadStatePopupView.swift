import UIKit

final class AudioDownloadStatePopupView: PopupView {

    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "audio download"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .black
        return titleLabel
    }()
    private(set) var progress: UIProgressView = {
        let progress = UIProgressView()
        return progress
    }()
    private(set) var downloadStateSymbolImageView: UIImageView = {
        let downloadStateSymbolImageView = UIImageView()
        downloadStateSymbolImageView.image = UIImage(systemName: "arrow.down.circle")
        downloadStateSymbolImageView.translatesAutoresizingMaskIntoConstraints = false
        downloadStateSymbolImageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        downloadStateSymbolImageView.contentMode = .scaleAspectFit
        return downloadStateSymbolImageView
    }()
    private(set) var downloadStateLabel: UILabel = {
        let downloadStateLabel = UILabel()
        downloadStateLabel.text = "downloading..."
        downloadStateLabel.textColor = .black
        return downloadStateLabel
    }()
    private let doneButton: DynamicBackgrounColordButton = {
        let doneButton = DynamicBackgrounColordButton()

        doneButton.setBackgroundColor(.systemBlue, for: .normal)
        doneButton.setBackgroundColor(.lightGray, for: .disabled)
        doneButton.backgroundColor = .systemBlue
        doneButton.tintColor = .white
        doneButton.isEnabled = false
        doneButton.layer.cornerRadius = 5
        doneButton.configuration = .plain()
        doneButton.configuration?.contentInsets = NSDirectionalEdgeInsets(
            top: 12, leading: 0, bottom: 12, trailing: 0)

        var titleAttr = AttributedString.init("done")
        titleAttr.font = .systemFont(ofSize: 15, weight: .regular)
        doneButton.configuration?.attributedTitle = titleAttr

        return doneButton
    }()

    override func popupViewDetailConfigure() {
        alertContainer.addArrangedSubview(titleLabel)
        alertContainer.addArrangedSubview(downloadStateSymbolImageView)
        alertContainer.addArrangedSubview(progress)
        alertContainer.addArrangedSubview(downloadStateLabel)
        alertContainer.addArrangedSubview(doneButton)
        doneButton.addAction(UIAction { _ in super.dismiss() }, for: .touchUpInside)
    }

    func setStateToFail() {
        progress.isHidden = true
        doneButton.isEnabled = true
        downloadStateLabel.text = "invalid download code"
        downloadStateSymbolImageView.image = UIImage(systemName: "xmark.circle")
        downloadStateSymbolImageView.tintColor = .systemPink
    }
}
