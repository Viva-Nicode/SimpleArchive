import Combine
import UIKit

final class FullScreenAudioComponentViewController: ComponentFullScreenView<AudioComponentContentView> {

    init(title: String, createdDate: Date, audioComponentContentView: AudioComponentContentView) {
        super.init(componentContentView: audioComponentContentView)
        super.setupUI()
        super.setupConstraints()

        setupData(title: title, date: createdDate)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
	
	override func applyColor(_ colorManager: any AppAppearanceManagerType = AppAppearanceManager.shared) {
		super.applyColor()
		toolBarView.backgroundColor = UIColor(named: "AudioComponentToolbarColor")?
			.setBrightness(min(1.0, colorManager.appBaseColorBrightness * 1.4))
		
	}
}
