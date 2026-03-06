import Combine
import SFBAudioEngine
import UIKit

final class SingleAudioPageViewController: UIViewController, AudioControlBarActionStrategy {
    private(set) var titleLable: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()
    private(set) var backgroundImageView: UIImageView = {
        let backgroundImageView = UIImageView()
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        return backgroundImageView
    }()
    private(set) var backgroundImageWindow: UIView = {
        let backgroundImageWindow = UIView()
        backgroundImageWindow.alpha = 0
        backgroundImageWindow.translatesAutoresizingMaskIntoConstraints = false
        return backgroundImageWindow
    }()
    private(set) var audioComponentContentView: AudioComponentContentView = {
        let audioComponentContentView = AudioComponentContentView()
        audioComponentContentView.backgroundColor = .clear
        audioComponentContentView.translatesAutoresizingMaskIntoConstraints = false
        return audioComponentContentView
    }()

    var dispatcher: AudioComponentActionDispatcher?
    var subscriptions = Set<AnyCancellable>()

    init() {
        super.init(nibName: nil, bundle: nil)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let coordinator = navigationController?.transitionCoordinator ?? transitionCoordinator
        let targetWindow = view.window ?? navigationController?.view.window
        if let host = targetWindow as? HostUIWindow {
            host.setStrategy(st: self, coordinatedBy: coordinator)
        }
    }

    deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }

    func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(backgroundImageView)
        backgroundImageView.alpha = 0
        backgroundImageWindow.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
        backgroundImageView.addSubview(backgroundImageWindow)

        view.addSubview(titleLable)
        view.addSubview(audioComponentContentView)
        audioComponentContentView.backgroundColor = .clear
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            backgroundImageWindow.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageWindow.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageWindow.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageWindow.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            titleLable.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            titleLable.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            audioComponentContentView.topAnchor.constraint(equalTo: titleLable.bottomAnchor, constant: 10),
            audioComponentContentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            audioComponentContentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            audioComponentContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func configure(dispatcher: AudioComponentActionDispatcher, audioComponent: AudioComponent) {
        self.dispatcher = dispatcher
        titleLable.text = audioComponent.title
        audioComponentContentView.configure(audioComponent: audioComponent, dispatcher: dispatcher)
    }

    func active(
        audioControlBar: AudioControlBarView,
        audioMetadata: AudioTrackMetadata,
        dispatcher: AudioComponentActionDispatcher?
    ) {
        if let thumbnailData = audioMetadata.thumbnail, let thumbnail = UIImage(data: thumbnailData) {
            updateBackgroundImage(with: thumbnail)
        }

        audioControlBar.isHidden = false
        audioControlBar.state = .play(metadata: audioMetadata, dispatcher: dispatcher)
    }

    func applyMetadataChange(
        audioControlBar: AudioControlBarView,
        audioMetadata: AudioTrackMetadata
    ) {
        if let thumbnailData = audioMetadata.thumbnail, let thumbnail = UIImage(data: thumbnailData) {
            updateBackgroundImage(with: thumbnail)
        }

        audioControlBar.applyUpdatedMetadata(with: audioMetadata)
    }

    private func updateBackgroundImage(with image: UIImage) {
        UIView.transition(
            with: self.backgroundImageView, duration: 1, options: .transitionCrossDissolve,
            animations: {
                self.backgroundImageView.image = image.blurred(radius: 7)
            }, completion: nil)

        UIView.animate(
            withDuration: 1,
            animations: {
                self.backgroundImageWindow.alpha =
                    self.traitCollection.userInterfaceStyle == .dark ? 0.4 : 0.3
                self.backgroundImageView.alpha = 1
            }
        )
    }
}
