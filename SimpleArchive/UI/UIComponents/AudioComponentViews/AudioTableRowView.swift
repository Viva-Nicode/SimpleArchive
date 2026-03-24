import SFBAudioEngine
import UIKit

final class AudioTableRowView: UITableViewCell {
    private let containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()
    private(set) var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.textAlignment = .left
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()
    private(set) var artistLabel: UILabel = {
        let artistLabel = UILabel()
        artistLabel.textAlignment = .left
        artistLabel.textColor = .label
        artistLabel.font = .systemFont(ofSize: 14)
        artistLabel.numberOfLines = 1
        artistLabel.translatesAutoresizingMaskIntoConstraints = false
        return artistLabel
    }()
    private(set) var thumbnailImageView: UIImageView = {
        let thumbnailImageView = UIImageView()
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        return thumbnailImageView
    }()
    private(set) var audioVisualizer: AudioVisualizerView = {
        let imageView = AudioVisualizerView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private var thumbnailHeightConstraint: NSLayoutConstraint?
    private var titleHeightConstraint: NSLayoutConstraint?
    private var artistHeightConstraint: NSLayoutConstraint?
    private var visualizerHeightConstraint: NSLayoutConstraint?
    private var visualizerTopConstraint: NSLayoutConstraint?

    static let reuseIdentifier = "AudioTableRowViewReuseIdentifier"
    var isNeedSetupShadow: Bool = true

    override func prepareForReuse() {
        super.prepareForReuse()

        isHidden = false

		thumbnailHeightConstraint?.constant = 45
		titleHeightConstraint?.constant = 30
		artistHeightConstraint?.constant = 15
        visualizerHeightConstraint?.constant = 45
        visualizerTopConstraint?.constant = 10

        titleLabel.text = nil
        artistLabel.text = nil
        thumbnailImageView.image = nil

        audioVisualizer.removeVisuzlization()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) { return }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { audioVisualizer.removeVisuzlization() }

    func setupUI() {
		thumbnailHeightConstraint = thumbnailImageView.heightAnchor.constraint(equalToConstant: 45)
		titleHeightConstraint = titleLabel.heightAnchor.constraint(equalToConstant: 30)
        artistHeightConstraint = artistLabel.heightAnchor.constraint(equalToConstant: 15)
        visualizerHeightConstraint = audioVisualizer.heightAnchor.constraint(equalToConstant: 45)
        visualizerTopConstraint = audioVisualizer.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10)

        contentView.backgroundColor = .clear
        backgroundColor = .clear

        contentView.addSubview(containerView)

        containerView.addSubview(thumbnailImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(artistLabel)
        containerView.addSubview(audioVisualizer)
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            thumbnailImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            thumbnailImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 45),
			thumbnailHeightConstraint!,

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -70),
			titleHeightConstraint!,

            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            artistLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 10),
            artistLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -60),
            artistHeightConstraint!,

            visualizerTopConstraint!,
            visualizerHeightConstraint!,
            audioVisualizer.widthAnchor.constraint(equalToConstant: 40),
            audioVisualizer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
        ])
    }

    func configure(audioTrack: AudioTrack, isSearchingResult: Bool) {
        isHidden = !isSearchingResult

        titleLabel.text = audioTrack.title
        artistLabel.text = audioTrack.artist
        thumbnailImageView.image = UIImage(data: audioTrack.thumbnail)

        if !isSearchingResult {
            audioVisualizer.removeVisuzlization()

			thumbnailHeightConstraint?.constant = 0
			titleHeightConstraint?.constant = 0
            artistHeightConstraint?.constant = 0
            visualizerTopConstraint?.constant = 0
            visualizerHeightConstraint?.constant = 0
        }

        layoutIfNeeded()
    }

    func setHighlighting(_ highlighted: Bool) {
        UIView.animate(withDuration: highlighted ? 0 : 0.3) {
            super.setHighlighted(highlighted, animated: false)
            self.contentView.backgroundColor = highlighted ? .systemGreen.withAlphaComponent(0.25) : .clear
        }
    }

    func updateAudioMetadata(_ data: AudioTrackMetadata) {
        if let title = data.title {
            titleLabel.text = title
        }
        if let artist = data.artist {
            artistLabel.text = artist
        }
        if let thumbnailData = data.thumbnail {
            thumbnailImageView.image = UIImage(data: thumbnailData)
        }
    }

    func setupShadow() {
        layoutIfNeeded()

        let shadowLayer = CALayer()
        shadowLayer.frame = thumbnailImageView.frame
        shadowLayer.backgroundColor = UIColor.white.cgColor
        shadowLayer.cornerRadius = 8

        shadowLayer.shadowColor = UIColor.gray.cgColor
        shadowLayer.shadowOpacity = 0.7

        shadowLayer.shadowRadius = 3
        shadowLayer.shadowOffset = .init(width: 0, height: 1)
        shadowLayer.masksToBounds = false

        if let superlayer = thumbnailImageView.superview?.layer {
            superlayer.insertSublayer(shadowLayer, below: thumbnailImageView.layer)
        }
    }
}
