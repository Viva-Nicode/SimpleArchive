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
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        return thumbnailImageView
    }()
    private(set) var audioVisualizer: AudioVisualizerView = {
        let imageView = AudioVisualizerView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    static let reuseIdentifier = "AudioTableRowViewReuseIdentifier"
    var isNeedSetupShadow: Bool = true

    override func prepareForReuse() {
        super.prepareForReuse()

        titleLabel.text = nil
        artistLabel.text = nil
        thumbnailImageView.image = nil
        audioVisualizer.removeVisuzlization()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
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

            thumbnailImageView.widthAnchor.constraint(equalToConstant: 45),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 45),
            thumbnailImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            thumbnailImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 10),
            titleLabel.heightAnchor.constraint(equalToConstant: 30),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -60),

            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            artistLabel.heightAnchor.constraint(equalToConstant: 15),
            artistLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 10),
            artistLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -60),

            audioVisualizer.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 17),
            audioVisualizer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -17),
            audioVisualizer.widthAnchor.constraint(equalToConstant: 30),
            audioVisualizer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
        ])
    }

    func configure(audioTrack: AudioTrack) {
        titleLabel.text = audioTrack.title
        artistLabel.text = audioTrack.artist
        thumbnailImageView.image = UIImage(data: audioTrack.thumbnail)
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
