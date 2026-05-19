import Combine
import UIKit

final class SignatureToleranceAdjustingView: UIControl {
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
    private let innerShadowLayer = CAShapeLayer()
    private(set) var innerWhiteShadowLayer = CAShapeLayer()

    private var circleXConstraint: NSLayoutConstraint?
    private var circleYConstraint: NSLayoutConstraint?

    private var xMaximum: Double?
    private var yMaximum: Double?
    private var xMinimum: Double?
    private var yMinimum: Double?

    var dispatcher: PassthroughSubject<MemoHomeViewInput, Never>?

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(circleThumb)
    }

    private func setupConstraints() {
        circleXConstraint = circleThumb.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0)
        circleYConstraint = circleThumb.topAnchor.constraint(equalTo: topAnchor, constant: 0)
        NSLayoutConstraint.activate([
            circleThumb.widthAnchor.constraint(equalToConstant: 30),
            circleThumb.heightAnchor.constraint(equalToConstant: 30),
            circleXConstraint!,
            circleYConstraint!,
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        innerShadowLayer.removeFromSuperlayer()
        innerWhiteShadowLayer.removeFromSuperlayer()

        innerShadowLayer.frame = bounds
        innerWhiteShadowLayer.frame = bounds

        layer.cornerRadius = 15
        layer.addSublayer(innerShadowLayer)
        layer.addSublayer(innerWhiteShadowLayer)

        let path = UIBezierPath(roundedRect: bounds.insetBy(dx: -7, dy: -7), cornerRadius: 15)
        let cutout = UIBezierPath(roundedRect: bounds, cornerRadius: 15).reversing()
        path.append(cutout)

        innerShadowLayer.cornerRadius = 15
        innerShadowLayer.shadowPath = path.cgPath
        innerShadowLayer.masksToBounds = true
        innerShadowLayer.shadowColor = UIColor.black.cgColor
        innerShadowLayer.shadowOffset = .init(width: -3, height: 3)
        innerShadowLayer.shadowOpacity = 0.12
        innerShadowLayer.shadowRadius = 5
        innerShadowLayer.fillRule = .evenOdd

        innerWhiteShadowLayer.cornerRadius = 15
        innerWhiteShadowLayer.shadowPath = path.cgPath
        innerWhiteShadowLayer.masksToBounds = true
        innerWhiteShadowLayer.shadowColor = UIColor.white.cgColor
        innerWhiteShadowLayer.shadowOffset = .init(width: 3, height: -3)
        innerWhiteShadowLayer.shadowRadius = 5
        innerWhiteShadowLayer.fillRule = .evenOdd
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
        circleXConstraint?.constant = min(140, max(0, touch.location(in: self).x - 15))
        circleYConstraint?.constant = min(140, max(0, touch.location(in: self).y - 15))
        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        guard let xMaximum, let xMinimum, let yMinimum, let yMaximum else { return }
        let xProgress = (circleXConstraint?.constant ?? 0) / 140
        let yProgress = (circleYConstraint?.constant ?? 0) / 140

        let xValue = xMinimum + (xMaximum - xMinimum) * Double(xProgress)
        let yValue = yMinimum + (yMaximum - yMinimum) * Double(yProgress)

        dispatcher?.send(.willAdjustSignaturePassScore(0.1 + 0.3 - yValue, xValue))
    }

    func setXRange(minimum: Double, maximum: Double, current: Double) {
        xMinimum = minimum
        xMaximum = maximum

        let clamped = min(maximum, max(minimum, current))
        let progress = (clamped - minimum) / (maximum - minimum)
        circleXConstraint?.constant = progress * 140
        layoutIfNeeded()
    }

    func setYRange(minimum: Double, maximum: Double, current: Double) {
        yMinimum = minimum
        yMaximum = maximum

        let clamped = min(maximum, max(minimum, current))
        let progress = (clamped - minimum) / (maximum - minimum)

        circleYConstraint?.constant = (1 - progress) * 140
        layoutIfNeeded()
    }
}
