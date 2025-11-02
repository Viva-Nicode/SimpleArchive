import Combine
import UIKit

final class FullScreenAudioComponentViewController: ComponentFullScreenView<AudioComponentContentView> {

    init(audioComponent: AudioComponent, audioComponentContentView: AudioComponentContentView) {
        super.init(componentContentView: audioComponentContentView)
        super.setupUI()
        super.setupConstraints()
        toolBarView.backgroundColor = UIColor(named: "AudioComponentToolbarColor")

        setupData(title: audioComponent.title, date: audioComponent.creationDate)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { print("FullScreenAudioComponentViewController deinit") }

    override var toolbarColor: UIColor? {
        UIColor(named: "AudioComponentToolbarColor")
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
