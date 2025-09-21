import UIKit

final class NeumorphicTextView: UITextView {

    private let innerShadowLayer = CALayer()

    private let outerShadowOffset: CGSize = .init(width: -3, height: 3)
    private let outerShadowOpacity: Float = 0.6
    private let outerShadowRadius: CGFloat = 4

    private let innerShadowOffset: CGSize = .init(width: -19, height: 19)
    private let innerShadowOpacity: Float = 0.2
    private let innerShadowRadius: CGFloat = 20

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        commonInit()

        self.backgroundColor = UIColor(red: 0.94, green: 0.96, blue: 0.98, alpha: 1)
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = false

        self.layer.shadowColor = UIColor(white: 0.7, alpha: 1).cgColor
        self.layer.shadowOffset = outerShadowOffset
        self.layer.shadowOpacity = outerShadowOpacity
        self.layer.shadowRadius = outerShadowRadius

        innerShadowLayer.frame = bounds
        innerShadowLayer.cornerRadius = layer.cornerRadius
        innerShadowLayer.backgroundColor = backgroundColor?.cgColor
        innerShadowLayer.masksToBounds = true

        self.layer.insertSublayer(innerShadowLayer, at: 0)

        applyInnerShadow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        innerShadowLayer.frame = bounds
        applyInnerShadow()
    }

    private func applyInnerShadow() {
        let radius = layer.cornerRadius
        innerShadowLayer.sublayers?.forEach { $0.removeFromSuperlayer() }

        let path = UIBezierPath(
            roundedRect: innerShadowLayer.bounds.insetBy(dx: -16, dy: -16),
            cornerRadius: radius)
        let cutout = UIBezierPath(
            roundedRect: innerShadowLayer.bounds.insetBy(dx: -6, dy: -6),
            cornerRadius: radius
        )
        .reversing()

        path.append(cutout)

        let topLeftShadow = CAShapeLayer()
        topLeftShadow.frame = innerShadowLayer.bounds
        topLeftShadow.shadowPath = path.cgPath
        topLeftShadow.masksToBounds = true
        topLeftShadow.shadowColor = UIColor.black.cgColor

        topLeftShadow.shadowOffset = innerShadowOffset
        topLeftShadow.shadowOpacity = innerShadowOpacity
        topLeftShadow.shadowRadius = innerShadowRadius

        topLeftShadow.fillRule = .evenOdd

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

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        textContainerInset = .init(top: 10, left: 10, bottom: 10, right: 10)
        autocorrectionType = .no
        spellCheckingType = .no
        autocapitalizationType = .none
        font = .systemFont(ofSize: 16)
        textColor = .black

        backgroundColor = UIColor(red: 0.94, green: 0.96, blue: 0.98, alpha: 1)
        layer.cornerRadius = 10
        layer.masksToBounds = false

        translatesAutoresizingMaskIntoConstraints = false
    }
}
