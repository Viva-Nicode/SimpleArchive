import UIKit

final class AppBaseColorBrightnessSlider: UIControl {
    private var circleThumb: UIView = {
        let circle = UIView()
        circle.backgroundColor = .white.withAlphaComponent(0.8)
        circle.layer.cornerRadius = 15
        circle.isUserInteractionEnabled = false
        circle.layer.masksToBounds = true
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.layer.zPosition = 99

        let innerShadowLayer = CAShapeLayer()

        let frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        innerShadowLayer.frame = frame

        circle.layer.addSublayer(innerShadowLayer)

        let path = UIBezierPath(roundedRect: frame.insetBy(dx: -13, dy: -13), cornerRadius: 15)
        let cutout = UIBezierPath(roundedRect: frame, cornerRadius: 15).reversing()
        path.append(cutout)

        innerShadowLayer.cornerRadius = 15
        innerShadowLayer.shadowPath = path.cgPath
        innerShadowLayer.masksToBounds = true
        innerShadowLayer.shadowColor = UIColor.black.cgColor
        innerShadowLayer.shadowOffset = .init(width: 3, height: -3)
        innerShadowLayer.shadowOpacity = 0.12
        innerShadowLayer.shadowRadius = 3
        innerShadowLayer.fillRule = .evenOdd

        let blurBackgroundView: UIVisualEffectView = {
            let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            let blurView = UIVisualEffectView(effect: blurEffect)

            blurView.layer.cornerRadius = 15
            blurView.isUserInteractionEnabled = false
            blurView.clipsToBounds = true
            return blurView
        }()

        blurBackgroundView.backgroundColor = .clear
        blurBackgroundView.frame = .init(x: -10, y: -10, width: 30, height: 30)
        blurBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        circle.addSubview(blurBackgroundView)
        circle.sendSubviewToBack(blurBackgroundView)
        return circle
    }()

    private let maxValue: Double
    private let minValue: Double
    private let currentValue: Double
    private let minimumLocation: CGFloat = 0
    private let maximumLocation: CGFloat = 140

    private let innerShadowLayer = CAShapeLayer()
    private var update: ((Double) -> Void)?
    private var end: ((Double) -> Void)?
    private var circleLeadingConstraint: NSLayoutConstraint?

    init(
        minValue: Double, maxValue: Double, currentValue: Double,
        update: ((Double) -> Void)?, end: ((Double) -> Void)? = nil
    ) {
        self.minValue = minValue
        self.maxValue = maxValue
        self.currentValue = currentValue
        self.update = update
        self.end = end
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        innerShadowLayer.removeFromSuperlayer()

        innerShadowLayer.frame = bounds
        layer.cornerRadius = bounds.height * 0.5
        layer.addSublayer(innerShadowLayer)

        let path = UIBezierPath(roundedRect: bounds.insetBy(dx: -7, dy: -7), cornerRadius: bounds.height * 0.5)
        let cutout = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.height * 0.5).reversing()
        path.append(cutout)

        innerShadowLayer.cornerRadius = bounds.height * 0.5
        innerShadowLayer.shadowPath = path.cgPath
        innerShadowLayer.masksToBounds = true
        innerShadowLayer.shadowColor = UIColor.black.cgColor
        innerShadowLayer.shadowOffset = .init(width: -2, height: 2)
        innerShadowLayer.shadowOpacity = 0.12
        innerShadowLayer.shadowRadius = 4
        innerShadowLayer.fillRule = .evenOdd
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(circleThumb)
    }

    func gestureRecognizer(_ g: UIGestureRecognizer, shouldBeRequiredToFailBy other: UIGestureRecognizer) -> Bool {
        return false
    }

    private func setupConstraints() {
        let progress = (currentValue - minValue) / (maxValue - minValue)
        let currentValue = minimumLocation + progress * (maximumLocation - minimumLocation)
        circleLeadingConstraint = circleThumb.leadingAnchor.constraint(equalTo: leadingAnchor, constant: currentValue)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 170),
            heightAnchor.constraint(equalToConstant: 15),

            circleThumb.widthAnchor.constraint(equalToConstant: 30),
            circleThumb.heightAnchor.constraint(equalToConstant: 30),
            circleThumb.centerYAnchor.constraint(equalTo: centerYAnchor),
            circleLeadingConstraint!,
        ])
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        circleThumb.frame.insetBy(dx: -10, dy: -10).contains(point)
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        let thumbFrame = circleThumb.frame.insetBy(dx: -10, dy: -10)
        return thumbFrame.contains(location)
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        handleBrightness(touch: touch)
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        guard let touch else { return }
        let nc = min(maximumLocation, max(minimumLocation, touch.location(in: self).x - 15))
        let progress = (nc - minimumLocation) / (maximumLocation - minimumLocation)
        let brightness = minValue + progress * (maxValue - minValue)
        end?(brightness)
    }

    private func handleBrightness(touch: UITouch) -> Bool {
        let nc = min(maximumLocation, max(minimumLocation, touch.location(in: self).x - 15))
        circleLeadingConstraint?.constant = nc
        let progress = (nc - minimumLocation) / (maximumLocation - minimumLocation)
        let brightness = minValue + progress * (maxValue - minValue)
        update?(brightness)
        return true
    }
}
