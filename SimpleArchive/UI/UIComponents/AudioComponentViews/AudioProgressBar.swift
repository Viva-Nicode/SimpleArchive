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
    private(set) var isPlaying: Bool = false

    let touchPadding: CGFloat = 17.0
    var minimumValue: TimeInterval = 0.0
    var maximumValue: TimeInterval = 1.0 {
        didSet { updateProgressLayout() }
    }
    var value: TimeInterval = 0.0 {
        didSet {
            value = min(max(value, minimumValue), maximumValue)
            updateProgressLayout()
            updateCurrentTimeLabel?(value)
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
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        self.backgroundColor = .clear

        addSubview(trackView)
        addSubview(progressView)

        // Auto Layout이 아닌 layoutSubviews에서 프레임을 직접 계산합니다.
        // 이유는 바의 너비가 빈번하게 변하기 때문입니다.
    }

    func start() {
        guard !isPlaying else { return }
        isPlaying = true

        lastUpdateTime = CACurrentMediaTime()
        displayLink = CADisplayLink(target: self, selector: #selector(updatePlaybackProgress))
        displayLink?.add(to: .main, forMode: .common)
    }

    func pause() {
        isPlaying = false
        displayLink?.invalidate()
        displayLink = nil
    }

    func setValue(_ newValue: TimeInterval) {
        // 사용자가 터치 중일 때(tracking) 외부에서 값을 강제로 바꾸면 튀는 현상이 발생하므로 방어
        guard !isTracking else { return }
        self.value = newValue
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // 외부에서 Auto Layout으로 이 뷰(MusicProgressBar)의 크기를 정해주면
        // 그 크기에 맞춰 서브뷰들의 프레임을 잡습니다.
        trackView.frame = bounds
        updateProgressLayout()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // 원래 뷰의 크기(bounds)보다 상하좌우로 touchPadding만큼 더 큰 사각형을 만듦
        let expandedBounds = bounds.insetBy(dx: -touchPadding, dy: -touchPadding)
        // 터치한 좌표가 이 커진 사각형 안에 있는지 확인
        return expandedBounds.contains(point)
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        // 스와이프가 시작되면 자동 재생 애니메이션을 잠깐 멈추거나 로직을 처리해야 한다면 여기서 함
        // 여기서는 값을 업데이트하고 이벤트를 보냄
        updateValue(from: touch)
        return true
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        updateValue(from: touch)
        // .valueChanged 이벤트 발생 -> 외부의 sliderValueChanged 호출됨
        sendActions(for: .valueChanged)
        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        // .touchUpInside / .touchUpOutside 이벤트 발생 -> 외부의 sliderValuecomp 호출됨
        // 보통 슬라이더는 떼는 순간 값을 확정하므로 touchUpInside를 주로 사용
        sendActions(for: .touchUpInside)
    }

    private func updateValue(from touch: UITouch) {
        let touchPoint = touch.location(in: self)
        let ratio = touchPoint.x / bounds.width
        let range = maximumValue - minimumValue

        let newValue = minimumValue + (range * TimeInterval(ratio))
        self.value = newValue  // didSet에서 레이아웃 업데이트됨
    }

    private func updateProgressLayout() {
        let totalWidth = bounds.width
        let range = maximumValue - minimumValue

        // 0으로 나누기 방지
        guard range > 0 else {
            progressView.frame = CGRect(x: 0, y: 0, width: 0, height: bounds.height)
            return
        }

        let progress = CGFloat((value - minimumValue) / range)
        let currentWidth = totalWidth * progress

        progressView.frame = CGRect(x: 0, y: 0, width: currentWidth, height: bounds.height)
    }

    @objc private func updatePlaybackProgress() {
        // 사용자가 조작 중(스와이프 중)일 때는 자동 업데이트를 막아야 함
        guard !isTracking else {
            lastUpdateTime = CACurrentMediaTime()  // 시간 싱크만 맞춤
            return
        }

        let currentTime = CACurrentMediaTime()
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        // 현재 값에 경과 시간을 더함
        // 실제 음악 앱에서는 Player의 currentTimer를 가져와서 동기화하는 것이 더 정확하지만,
        // 요청하신 대로 뷰 자체에서 채워지는 로직을 구현함
        if value < maximumValue {
            value += deltaTime
        } else {
            // 끝까지 가면 멈춤
            pause()
        }
    }
}
