final class UnderlineTextField: UITextField {

    private let underlineLayer = CALayer()
    private let underlineHeight: CGFloat = 2
    private let textBottomPadding: CGFloat = 2

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        borderStyle = .none
        textColor = .black
        font = UIFont.systemFont(ofSize: 16)

        underlineLayer.backgroundColor = UIColor.systemBlue.cgColor
        layer.addSublayer(underlineLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        underlineLayer.frame = CGRect(
            x: 0,
            y: bounds.height - underlineHeight,
            width: bounds.width,
            height: underlineHeight
        )
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: underlineHeight + textBottomPadding, right: 0))
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }
}