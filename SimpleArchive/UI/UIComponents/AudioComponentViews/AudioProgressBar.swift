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
    private let progressBar: UIView = {
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
        didSet { updateProgressBarWidth() }
    }

    private(set) var currentProgress: TimeInterval = 0.0 {
        didSet {
            currentProgress = min(max(currentProgress, minimumValue), maximumValue)
            updateProgressBarWidth()
            if [.began, .changed, .ended, .cancelled, .failed].contains(panGesture?.state) {
                return
            }
            updateCurrentTimeLabel?(currentProgress)
        }
    }

    var isScrubbingEnabled: Bool = true {
        didSet {
            self.isUserInteractionEnabled = isScrubbingEnabled
        }
    }

    private var panGesture: UIPanGestureRecognizer?

    func setGesture(panGesture: UIPanGestureRecognizer) {
        self.panGesture = panGesture
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
        addSubview(progressBar)
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

    func setCurrentProgress(_ progress: TimeInterval) { currentProgress = progress }

    override func layoutSubviews() {
        super.layoutSubviews()

        trackView.frame = bounds
        updateProgressBarWidth()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let expandedBounds = bounds.insetBy(dx: -touchPadding, dy: -touchPadding)
        return expandedBounds.contains(point)
    }

    private func updateCurrentProgressWithTracking(from touch: UITouch) {
        let touchPoint = touch.location(in: self)
        let ratio = Double(touchPoint.x / bounds.width)

        currentProgress = minimumValue + (maximumValue * ratio)
    }

    private func updateProgressBarWidth() {
        let totalWidth = bounds.width
        let progress = CGFloat(currentProgress / maximumValue)
        let currentWidth = totalWidth * progress

        progressBar.frame = CGRect(x: 0, y: 0, width: currentWidth, height: bounds.height)
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        panGesture?.isEnabled = false
        updateCurrentProgressWithTracking(from: touch)
        return true
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        updateCurrentProgressWithTracking(from: touch)
        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        panGesture?.isEnabled = true
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
            pauseProgress()
        }
    }
}
