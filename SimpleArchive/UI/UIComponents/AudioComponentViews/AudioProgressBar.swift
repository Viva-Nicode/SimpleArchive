import UIKit

final class AudioProgressBar: UIControl {

    private let trackView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray3
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = 2.5
        view.clipsToBounds = true
        return view
    }()
    private let progressView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemOrange
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = 2.5
        return view
    }()

    var updateCurrentTimeLabel: ((TimeInterval) -> Void)?

    private var displayLink: CADisplayLink?
    private var lastUpdateTime: CFTimeInterval = 0

    let touchPadding: CGFloat = 13.0
    var minimumValue: TimeInterval = 0.0
    var maximumValue: TimeInterval = 1.0 {
        didSet { updateProgressLayout() }
    }

    private(set) var currentProgress: TimeInterval = 0.0 {
        didSet {
            currentProgress = min(max(currentProgress, minimumValue), maximumValue)
            updateProgressLayout()
            updateCurrentTimeLabel?(currentProgress)
        }
    }

    var isScrubbingEnabled: Bool = true {
        didSet {
            self.isUserInteractionEnabled = isScrubbingEnabled
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupUI() {
        self.backgroundColor = .clear

        addSubview(trackView)
        addSubview(progressView)
    }

    func startProgress() {
        lastUpdateTime = CACurrentMediaTime()
        displayLink?.invalidate()
        displayLink = nil

        displayLink = CADisplayLink(target: self, selector: #selector(updatePlaybackProgress))
        displayLink?.add(to: .main, forMode: .common)
    }

    func pauseProgress() {
        displayLink?.invalidate()
        displayLink = nil
    }

    func setCurrentProgress(_ progress: TimeInterval) {
        self.currentProgress = progress
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        trackView.frame = bounds
        updateProgressLayout()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let expandedBounds = bounds.insetBy(dx: -touchPadding, dy: -touchPadding)
        return expandedBounds.contains(point)
    }

    private func updateCurrentProgressWithTracking(from touch: UITouch) {
        let touchPoint = touch.location(in: self)
        let ratio = touchPoint.x / bounds.width
        let range = maximumValue - minimumValue

        let newValue = minimumValue + (range * TimeInterval(ratio))
        self.currentProgress = newValue
    }

    private func updateProgressLayout() {
        let totalWidth = bounds.width
        let range = maximumValue - minimumValue
        let progress = CGFloat((currentProgress - minimumValue) / range)
        let currentWidth = totalWidth * progress

        progressView.frame = CGRect(x: 0, y: 0, width: currentWidth, height: bounds.height)
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        updateCurrentProgressWithTracking(from: touch)
        return true
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        updateCurrentProgressWithTracking(from: touch)
        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        sendActions(for: .touchUpInside)
    }

    @objc private func updatePlaybackProgress() {

        guard !isTracking else { return }

        let currentTime = CACurrentMediaTime()
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        if currentProgress < maximumValue {
            currentProgress += deltaTime
        } else {
            pause()
        }
    }
}
