import Combine
import UIKit

final class AudioComponentView: PageComponentView<AudioComponentContentView, AudioComponent> {

    static let reuseAudioComponentIdentifier: String = "reuseAudioComponentIdentifier"

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { print("deinit AudioComponentView") }

    override func setupUI() {
        componentContentView = AudioComponentContentView()
        componentContentView.translatesAutoresizingMaskIntoConstraints = false
        componentContentView.layer.cornerRadius = 10
        componentContentView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        componentContentView.backgroundColor = .systemGray6

        super.setupUI()

        toolBarView.backgroundColor = UIColor(named: "AudioComponentToolbarColor")
    }

    override func setupConstraints() {
        super.setupConstraints()
    }

    override func configure(
        component: AudioComponent,
        input subject: PassthroughSubject<MemoPageViewInput, Never>,
    ) {
        super.configure(component: component, input: subject)

        componentContentView.configure(
            content: component,
            dispatcher: MemoPageAudioComponentActionDispatcher(subject: subject),
            componentID: componentID
        )
    }

    override func setMinimizeState(_ isMinimize: Bool) {
        componentContentView.minimizeContentView(isMinimize)
    }
}
