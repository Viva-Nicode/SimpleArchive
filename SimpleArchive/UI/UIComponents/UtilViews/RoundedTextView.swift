import UIKit

@IBDesignable
class RoundedTextView: UITextView {

    @IBInspectable var cornerRadius: CGFloat = 12 {
        didSet { applyStyling() }
    }

    @IBInspectable var borderWidth: CGFloat = 1 {
        didSet { applyStyling() }
    }

    @IBInspectable var borderColor: UIColor = .systemGray4 {
        didSet { applyStyling() }
    }

    @IBInspectable var contentInsetHorizontal: CGFloat = 12 {
        didSet { updateTextContainerInset() }
    }

    @IBInspectable var contentInsetVertical: CGFloat = 8 {
        didSet { updateTextContainerInset() }
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        commonInit()
    }

    private func commonInit() {
        isScrollEnabled = true
        backgroundColor = .secondarySystemBackground
        font = .systemFont(ofSize: 15)
        textColor = .label
        
        if #available(iOS 13.0, *) {
            layer.cornerCurve = .continuous
        }
        applyStyling()
        updateTextContainerInset()
    }

    private func applyStyling() {
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
    }

    private func updateTextContainerInset() {
        textContainerInset = UIEdgeInsets(
            top: contentInsetVertical,
            left: contentInsetHorizontal,
            bottom: contentInsetVertical,
            right: contentInsetHorizontal
        )
    }
}
