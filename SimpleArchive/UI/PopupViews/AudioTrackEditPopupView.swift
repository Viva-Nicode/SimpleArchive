import CSFBAudioEngine
import Combine
import PhotosUI
import UIKit

final class AudioTrackEditPopupView: PopupView {

    private let albumThumbnailLabel: UILabel = {
        let albumThumbnailLabel = UILabel()
        albumThumbnailLabel.text = "Thumbnail"
        albumThumbnailLabel.textColor = .gray
        return albumThumbnailLabel
    }()
    private let thumbnailView: UIView = {
        let thumbnailStackView = UIStackView()
        thumbnailStackView.translatesAutoresizingMaskIntoConstraints = false
        return thumbnailStackView
    }()
    private let thumbnailImage: UIImageView = {
        let thumbnailImage = UIImageView()
        thumbnailImage.image = UIImage(named: "defaultMusicThumbnail")
        thumbnailImage.layer.cornerRadius = 8
        thumbnailImage.contentMode = .scaleAspectFill
        thumbnailImage.clipsToBounds = true
        thumbnailImage.isUserInteractionEnabled = true
        thumbnailImage.translatesAutoresizingMaskIntoConstraints = false
        return thumbnailImage
    }()
    private let albumTitleLabel: UILabel = {
        let albumTitleLabel = UILabel()
        albumTitleLabel.text = "Title"
        albumTitleLabel.textColor = .gray
        return albumTitleLabel
    }()
    private let albumArtistLabel: UILabel = {
        let albumArtistLabel = UILabel()
        albumArtistLabel.text = "Artist"
        albumArtistLabel.textColor = .gray
        return albumArtistLabel
    }()
    private let audioTrackTitleTextField: UnderlineTextField = {
        let audioTrackTitleTextField = UnderlineTextField()
        return audioTrackTitleTextField
    }()
    private let audioTrackArtistTextField: UnderlineTextField = {
        let audioTrackArtistTextField = UnderlineTextField()
        return audioTrackArtistTextField
    }()
    private let buttonContainer: UIStackView = {
        let buttonContainer = UIStackView()
        buttonContainer.axis = .horizontal
        buttonContainer.spacing = 15
        buttonContainer.alignment = .center
        buttonContainer.distribution = .fillEqually
        return buttonContainer
    }()
    private let confirmButton: DynamicBackgrounColordButton = {
        let confirmButton = DynamicBackgrounColordButton()

        confirmButton.setBackgroundColor(.systemBlue, for: .normal)
        confirmButton.setBackgroundColor(.lightGray, for: .disabled)
        confirmButton.backgroundColor = .systemBlue
        confirmButton.tintColor = .white
        confirmButton.layer.cornerRadius = 5
        confirmButton.configuration = .plain()
        confirmButton.configuration?.contentInsets = NSDirectionalEdgeInsets(
            top: 12, leading: 0, bottom: 12, trailing: 0)

        var titleAttr = AttributedString.init("Yes, Change!")
        titleAttr.font = .systemFont(ofSize: 15, weight: .regular)
        confirmButton.configuration?.attributedTitle = titleAttr

        return confirmButton
    }()
    private let cancelButton: UIButton = {
        var buttonConfiguration = UIButton.Configuration.filled()
        var titleAttr = AttributedString.init("No, Keep It.")

        buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
        buttonConfiguration.baseBackgroundColor = .systemPink

        titleAttr.font = .systemFont(ofSize: 15, weight: .regular)
        buttonConfiguration.attributedTitle = titleAttr

        return UIButton(configuration: buttonConfiguration)
    }()

    var confirmButtonPublisher: AnyPublisher<AudioTrackMetadata, Never> {
        confirmButton.throttleTapPublisher()
            .map { _ in
                AudioTrackMetadata(
                    title: self.audioTrackTitleTextField.text,
                    artist: self.audioTrackArtistTextField.text,
                    thumbnail: self.thumbnailImage.image?.jpegData(compressionQuality: 1.0))
            }
            .eraseToAnyPublisher()
    }

    init(title: String?, artist: String?, thumbnail: UIImage?) {
        thumbnailImage.image = thumbnail
        audioTrackTitleTextField.text = title
        audioTrackArtistTextField.text = artist
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { print("AudioTrackEditPopupView deinit") }

    override func popupViewDetailConfigure() {

        cancelButton.addAction(UIAction { _ in self.dismiss() }, for: .touchUpInside)

        alertContainer.addArrangedSubview(albumThumbnailLabel)
        alertContainer.setCustomSpacing(6, after: albumThumbnailLabel)

        alertContainer.addArrangedSubview(thumbnailView)
        thumbnailView.heightAnchor.constraint(equalToConstant: 100).isActive = true

        thumbnailView.addSubview(thumbnailImage)

        thumbnailImage.throttleUIViewTapGesturePublisher()
            .sink { _ in
                var configuration = PHPickerConfiguration()

                configuration.selectionLimit = 1
                configuration.filter = .any(of: [.images])

                let picker = PHPickerViewController(configuration: configuration)
                picker.delegate = self
                self.parentViewController?.present(picker, animated: true)
            }
            .store(in: &subscriptions)
        thumbnailImage.heightAnchor.constraint(equalToConstant: 100).isActive = true
        thumbnailImage.widthAnchor.constraint(equalToConstant: 100).isActive = true
        thumbnailImage.centerXAnchor.constraint(equalTo: thumbnailView.centerXAnchor).isActive = true
        thumbnailImage.centerYAnchor.constraint(equalTo: thumbnailView.centerYAnchor).isActive = true

        layoutIfNeeded()

        let shadowLayer = CALayer()
        shadowLayer.frame = thumbnailImage.frame

        shadowLayer.backgroundColor = UIColor.white.cgColor
        shadowLayer.cornerRadius = 8

        shadowLayer.shadowColor = UIColor.gray.cgColor
        shadowLayer.shadowOpacity = 0.7

        shadowLayer.shadowRadius = 3
        shadowLayer.shadowOffset = .init(width: 0, height: 1)
        shadowLayer.masksToBounds = false

        if let superlayer = thumbnailImage.superview?.layer {
            superlayer.insertSublayer(shadowLayer, below: thumbnailImage.layer)
        }

        alertContainer.addArrangedSubview(albumTitleLabel)
        alertContainer.setCustomSpacing(6, after: albumTitleLabel)
        alertContainer.addArrangedSubview(audioTrackTitleTextField)

        alertContainer.addArrangedSubview(albumArtistLabel)
        alertContainer.setCustomSpacing(6, after: albumArtistLabel)
        alertContainer.addArrangedSubview(audioTrackArtistTextField)

        buttonContainer.addArrangedSubview(cancelButton)
        buttonContainer.addArrangedSubview(confirmButton)
        alertContainer.addArrangedSubview(buttonContainer)
    }
}

extension AudioTrackEditPopupView: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)

        let itemProvider = results.first?.itemProvider

        if let itemProvider = itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                DispatchQueue.main.async {
                    self.thumbnailImage.image = (image as? UIImage)?.audioTrackThumbnailSquared
                }
            }
        }
    }
}
