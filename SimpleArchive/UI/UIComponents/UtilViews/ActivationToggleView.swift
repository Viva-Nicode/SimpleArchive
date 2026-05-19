import UIKit

final class ActivationToggleView: UIControl {
    private var activeLabel: UILabel = {
        let activeLabel = UILabel()
        activeLabel.text = "active"
        activeLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        activeLabel.textColor = .label
        activeLabel.textAlignment = .center
        activeLabel.translatesAutoresizingMaskIntoConstraints = false
        return activeLabel
    }()
    private lazy var circleThumb: UIView = {
        let circle = UIView()
        circle.backgroundColor = .white.setBrightness(0.9)
        circle.layer.cornerRadius = 20
        circle.layer.masksToBounds = true
        circle.isUserInteractionEnabled = false
        circle.translatesAutoresizingMaskIntoConstraints = false

        let innerShadowLayer = CAShapeLayer()

        let frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        innerShadowLayer.frame = frame
        thumbInnerWhiteShadowLayer.frame = frame

        circle.layer.addSublayer(innerShadowLayer)
        circle.layer.addSublayer(thumbInnerWhiteShadowLayer)

        let path = UIBezierPath(roundedRect: frame.insetBy(dx: -13, dy: -13), cornerRadius: 20)
        let cutout = UIBezierPath(roundedRect: frame, cornerRadius: 20).reversing()
        path.append(cutout)

        innerShadowLayer.cornerRadius = 20
        innerShadowLayer.shadowPath = path.cgPath
        innerShadowLayer.masksToBounds = true
        innerShadowLayer.shadowColor = UIColor.black.cgColor
        innerShadowLayer.shadowOffset = .init(width: 3, height: -3)
        innerShadowLayer.shadowOpacity = 0.09
        innerShadowLayer.shadowRadius = 3
        innerShadowLayer.fillRule = .evenOdd

        thumbInnerWhiteShadowLayer.cornerRadius = 20
        thumbInnerWhiteShadowLayer.shadowPath = path.cgPath
        thumbInnerWhiteShadowLayer.masksToBounds = true
        thumbInnerWhiteShadowLayer.shadowColor = UIColor.white.cgColor
        thumbInnerWhiteShadowLayer.shadowOffset = .init(width: -3, height: 3)
        thumbInnerWhiteShadowLayer.shadowRadius = 3
        thumbInnerWhiteShadowLayer.fillRule = .evenOdd

        let blurBackgroundView: UIVisualEffectView = {
            let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            let blurView = UIVisualEffectView(effect: blurEffect)

            blurView.layer.cornerRadius = 20
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

    private(set) var thumbInnerWhiteShadowLayer = CAShapeLayer()
    private(set) var whiteInnerShadowLayer = CAShapeLayer()
    private let innerShadowLayer = CAShapeLayer()
    private var circleLeadingConstraint: NSLayoutConstraint?
    private var tapAction: (() -> Void)?

    init() {
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
        whiteInnerShadowLayer.removeFromSuperlayer()

        innerShadowLayer.frame = bounds
        whiteInnerShadowLayer.frame = bounds
        layer.cornerRadius = 25
        layer.addSublayer(innerShadowLayer)
        layer.addSublayer(whiteInnerShadowLayer)

        let path = UIBezierPath(roundedRect: bounds.insetBy(dx: -7, dy: -7), cornerRadius: 25)
        let cutout = UIBezierPath(roundedRect: bounds, cornerRadius: 25).reversing()
        path.append(cutout)

        innerShadowLayer.cornerRadius = 25
        innerShadowLayer.shadowPath = path.cgPath
        innerShadowLayer.masksToBounds = true
        innerShadowLayer.shadowColor = UIColor.black.cgColor
        innerShadowLayer.shadowOffset = .init(width: -4, height: 4)
        innerShadowLayer.shadowOpacity = 0.12
        innerShadowLayer.shadowRadius = 5
        innerShadowLayer.fillRule = .evenOdd

        whiteInnerShadowLayer.cornerRadius = 25
        whiteInnerShadowLayer.shadowPath = path.cgPath
        whiteInnerShadowLayer.masksToBounds = true
        whiteInnerShadowLayer.shadowColor = UIColor.white.cgColor
        whiteInnerShadowLayer.shadowOffset = .init(width: 4, height: -4)
        whiteInnerShadowLayer.shadowRadius = 5
        whiteInnerShadowLayer.fillRule = .evenOdd
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(activeLabel)
        addSubview(circleThumb)
    }

    private func setupConstraints() {
        circleLeadingConstraint = circleThumb.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 125)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 170),
            heightAnchor.constraint(equalToConstant: 50),

            circleThumb.widthAnchor.constraint(equalToConstant: 40),
            circleThumb.heightAnchor.constraint(equalToConstant: 40),
            circleThumb.centerYAnchor.constraint(equalTo: centerYAnchor),
            circleLeadingConstraint!,

            activeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            activeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @objc private func didTapToggle() {
        isUserInteractionEnabled = false
        let isOn = circleLeadingConstraint?.constant == 5
        circleLeadingConstraint?.constant = isOn ? 125 : 5
        UIView.curveEaseOut {
            self.layoutIfNeeded()
            self.activeLabel.alpha = isOn ? 1 : 0.2
            self.activeLabel.transform = isOn ? .init(scaleX: 1.1, y: 1.1) : .identity
            self.activeLabel.font = isOn ? .systemFont(ofSize: 18, weight: .semibold) : .systemFont(ofSize: 18)
        } comp: {
            self.isUserInteractionEnabled = true
        }
        tapAction?()
    }

    func setupGesture(action: @escaping () -> Void) {
        self.tapAction = action
        addTarget(self, action: #selector(didTapToggle), for: .touchUpInside)
    }

    func setActiveState(_ isActive: Bool) {
        circleLeadingConstraint?.constant = isActive ? 125 : 5
        activeLabel.alpha = isActive ? 1 : 0.2
        activeLabel.transform = isActive ? .init(scaleX: 1.1, y: 1.1) : .identity
        activeLabel.font = isActive ? .systemFont(ofSize: 18, weight: .semibold) : .systemFont(ofSize: 18)
    }
}
