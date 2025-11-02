import UIKit

final class NeumorphicButton: UIButton {

    private let innerShadowLayer = CALayer()

    private let outerShadowOffset: CGSize = .init(width: -6, height: 6)
    private let outerShadowOpacity: Float = 0.6
    private let outerShadowRadius: CGFloat = 15

    private let innerShadowOffset: CGSize = .init(width: -30, height: 30)
    private let innerShadowOpacity: Float = 0.1
    private let innerShadowRadius: CGFloat = 25

    init() {
        super.init(frame: .zero)
        configureStyle()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureStyle()
    }

    private func configureStyle() {
        self.backgroundColor = UIColor(red: 0.94, green: 0.96, blue: 0.98, alpha: 1)
        self.layer.cornerRadius = 20
        self.layer.masksToBounds = false
        self.translatesAutoresizingMaskIntoConstraints = false

        self.layer.shadowColor = UIColor(white: 0.7, alpha: 1).cgColor
        self.layer.shadowOffset = outerShadowOffset
        self.layer.shadowOpacity = outerShadowOpacity
        self.layer.shadowRadius = outerShadowRadius

        // 위쪽 하이라이트
        let topHighlight = CALayer()
        topHighlight.frame = bounds
        topHighlight.backgroundColor = backgroundColor?.cgColor
        topHighlight.cornerRadius = layer.cornerRadius
        topHighlight.shadowColor = UIColor.white.cgColor
        topHighlight.shadowOffset = CGSize(width: -6, height: -6)
        topHighlight.shadowOpacity = 1
        topHighlight.shadowRadius = 6
        self.layer.insertSublayer(topHighlight, at: 0)

        // 내부 그림자 레이어
        innerShadowLayer.frame = bounds
        innerShadowLayer.cornerRadius = layer.cornerRadius
        innerShadowLayer.backgroundColor = backgroundColor?.cgColor
        innerShadowLayer.masksToBounds = true
        self.layer.addSublayer(innerShadowLayer)

        applyInnerShadow()

        let icon = UIImageView(image: UIImage(systemName: "thermometer"))
        icon.tintColor = UIColor(red: 0, green: 0.3, blue: 0.25, alpha: 1)
        icon.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(icon)

        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: self.centerYAnchor),
        ])
    }

    private func applyInnerShadow() {
        let radius = layer.cornerRadius
        innerShadowLayer.sublayers?.forEach { $0.removeFromSuperlayer() }

        // 공통 path
        let path = UIBezierPath(roundedRect: innerShadowLayer.bounds.insetBy(dx: -22, dy: -22), cornerRadius: radius)
        let cutout = UIBezierPath(roundedRect: innerShadowLayer.bounds, cornerRadius: radius).reversing()
        path.append(cutout)

        // 좌측상단 그림자
        let topLeftShadow = CAShapeLayer()
        topLeftShadow.frame = innerShadowLayer.bounds
        topLeftShadow.shadowPath = path.cgPath
        topLeftShadow.masksToBounds = true
        topLeftShadow.shadowColor = UIColor.black.cgColor

        topLeftShadow.shadowOffset = innerShadowOffset
        topLeftShadow.shadowOpacity = innerShadowOpacity
        topLeftShadow.shadowRadius = innerShadowRadius

        topLeftShadow.fillRule = .evenOdd

        // 우측하단 그림자
        let bottomRightShadow = CAShapeLayer()
        bottomRightShadow.frame = innerShadowLayer.bounds
        bottomRightShadow.shadowPath = path.cgPath
        bottomRightShadow.masksToBounds = true
        bottomRightShadow.shadowColor = UIColor.black.cgColor

        bottomRightShadow.shadowOffset = innerShadowOffset
        bottomRightShadow.shadowOpacity = innerShadowOpacity
        bottomRightShadow.shadowRadius = innerShadowRadius

        bottomRightShadow.fillRule = .evenOdd

        innerShadowLayer.addSublayer(topLeftShadow)
        innerShadowLayer.addSublayer(bottomRightShadow)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        innerShadowLayer.frame = bounds
        applyInnerShadow()
    }
}
