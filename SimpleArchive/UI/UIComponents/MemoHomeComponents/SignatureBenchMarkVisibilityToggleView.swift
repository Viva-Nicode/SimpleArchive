import Combine
import UIKit

final class SignatureBenchMarkVisibilityToggleView: UIControl {
    private var circleThumb: UIView = {
        let circle = UIView()
        circle.backgroundColor = .white.withAlphaComponent(0.8)
        circle.layer.cornerRadius = 20
        circle.layer.masksToBounds = true
        circle.isUserInteractionEnabled = false
        circle.translatesAutoresizingMaskIntoConstraints = false

        let innerShadowLayer = CAShapeLayer()

        let frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        innerShadowLayer.frame = frame

        circle.layer.addSublayer(innerShadowLayer)

        let path = UIBezierPath(roundedRect: frame.insetBy(dx: -13, dy: -13), cornerRadius: 20)
        let cutout = UIBezierPath(roundedRect: frame, cornerRadius: 20).reversing()
        path.append(cutout)

        innerShadowLayer.cornerRadius = 20
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
    private(set) lazy var visibilityLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .center

        visibilityAttributedString.append(
            NSAttributedString(
                string: "VISIBLE",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                    .foregroundColor: UIColor.label,
                ]
            )
        )

        attachment.image = UIImage(systemName: "sparkles")?
            .withTintColor(UIColor.label, renderingMode: .alwaysOriginal)
        let imageString = NSAttributedString(attachment: attachment)

        visibilityAttributedString.append(imageString)
        visibilityAttributedString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: visibilityAttributedString.length)
        )

        titleLabel.attributedText = visibilityAttributedString
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()

    private let innerShadowLayer = CAShapeLayer()
    private(set) var innerWhiteShadowLayer = CAShapeLayer()
    private let visibilityAttributedString = NSMutableAttributedString()
    private let attachment = NSTextAttachment()
    private var circleLeadingConstraint: NSLayoutConstraint?
    var dispatcher: PassthroughSubject<MemoHomeViewInput, Never>?

    override func layoutSubviews() {
        super.layoutSubviews()
        innerShadowLayer.removeFromSuperlayer()
        innerWhiteShadowLayer.removeFromSuperlayer()

        innerShadowLayer.frame = bounds
        innerWhiteShadowLayer.frame = bounds

        layer.cornerRadius = 25
        layer.addSublayer(innerShadowLayer)
        layer.addSublayer(innerWhiteShadowLayer)

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

        innerWhiteShadowLayer.cornerRadius = 25
        innerWhiteShadowLayer.shadowPath = path.cgPath
        innerWhiteShadowLayer.masksToBounds = true
        innerWhiteShadowLayer.shadowColor = UIColor.white.cgColor
        innerWhiteShadowLayer.shadowOffset = .init(width: 4, height: -4)
        innerWhiteShadowLayer.shadowRadius = 5
        innerWhiteShadowLayer.fillRule = .evenOdd
    }

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
        addSubview(visibilityLabel)
        addSubview(circleThumb)
        addTarget(self, action: #selector(toggleBenchMarkVisibility), for: .touchUpInside)
    }

    private func setupConstraints() {
        circleLeadingConstraint = circleThumb.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 125)
        NSLayoutConstraint.activate([
            circleThumb.widthAnchor.constraint(equalToConstant: 40),
            circleThumb.heightAnchor.constraint(equalToConstant: 40),
            circleThumb.centerYAnchor.constraint(equalTo: centerYAnchor),
            circleLeadingConstraint!,

            visibilityLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            visibilityLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @objc private func toggleBenchMarkVisibility() {
        isUserInteractionEnabled = false
        let isOn = circleLeadingConstraint?.constant == 5
        dispatcher?.send(.willSetBenchmarkVisibility(isOn))
        circleLeadingConstraint?.constant = isOn ? 125 : 5

        UIView.animateKeyframes(withDuration: 0.4, delay: 0, options: .calculationModeLinear) {
            for i in 0..<8 {
                if isOn {
                    let attributed = NSMutableAttributedString(attributedString: self.visibilityAttributedString)
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                        UIView.transition(with: self.visibilityLabel, duration: 0.2, options: .transitionCrossDissolve)
                        {
                            let alpha = CGFloat(max(0.2, min(1.0, Double(i + 1) / 8.0)))

                            attributed.addAttribute(
                                .foregroundColor,
                                value: UIColor.label.withAlphaComponent(alpha),
                                range: NSRange(location: 0, length: i + 1)
                            )

                            let image = UIImage(systemName: "sparkles")?
                                .withTintColor(
                                    UIColor.label.withAlphaComponent(alpha),
                                    renderingMode: .alwaysOriginal)

                            self.attachment.image = image
                            self.visibilityLabel.attributedText = attributed
                        } completion: { _ in
                            if i == 7 { self.isUserInteractionEnabled = true }
                        }
                    }
                } else {
                    let attributed = NSMutableAttributedString(attributedString: self.visibilityAttributedString)
                    DispatchQueue.main.async {
                        UIView.transition(with: self.visibilityLabel, duration: 0.8, options: .transitionCrossDissolve)
                        {
                            let alpha = CGFloat(max(0.2, min(1.0, Double(8 - i) / 8.0)))

                            attributed.addAttribute(
                                .foregroundColor,
                                value: UIColor.label.withAlphaComponent(alpha),
                                range: NSRange(location: max(0, attributed.length - i - 3), length: min(7, i + 2))
                            )
                            let image = UIImage(systemName: "sparkles")?
                                .withTintColor(
                                    UIColor.label.withAlphaComponent(alpha),
                                    renderingMode: .alwaysOriginal)

                            self.attachment.image = image
                            self.visibilityLabel.attributedText = attributed
                        } completion: { _ in
                            if i == 7 { self.isUserInteractionEnabled = true }
                        }
                    }
                }
            }
            self.layoutIfNeeded()
        }
    }

    func setVisibility(_ visibility: Bool) {
        circleLeadingConstraint?.constant = visibility ? 125 : 5

        visibilityAttributedString.addAttribute(
            .foregroundColor,
            value: UIColor.label.withAlphaComponent(visibility ? 1.0 : 0.2),
            range: NSRange(location: 0, length: visibilityAttributedString.length - 1)
        )
        let image = UIImage(systemName: "sparkles")?
            .withTintColor(
                UIColor.label.withAlphaComponent(visibility ? 1.0 : 0.2),
                renderingMode: .alwaysOriginal)

        attachment.image = image
        visibilityLabel.attributedText = visibilityAttributedString
    }
}
