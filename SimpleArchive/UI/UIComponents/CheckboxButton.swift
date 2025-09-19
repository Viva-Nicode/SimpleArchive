import UIKit

final class CheckboxButton: UIButton {
    private(set) var isChecked = false {
        didSet { updateAppearance() }
    }
    
    private let title: String

    func setIsChecked(_ isChecked: Bool) {
        self.isChecked = isChecked
    }
    
    init(title: String) {
        self.title = title
        super.init(frame: .zero)
        configuration = .plain()
        tintColor = .black
        addTarget(self, action: #selector(toggle), for: .touchUpInside)
        updateAppearance()
        accessibilityTraits.insert(.button)
        accessibilityLabel = "Checkbox"
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func toggle() { isChecked.toggle() }

    private func updateAppearance() {
        let name = isChecked ? "checkmark.square.fill" : "square"
        let color: UIColor = isChecked ? .green : .gray
        let image = UIImage(systemName: name)?.withRenderingMode(.alwaysTemplate)
        setImage(image, for: .normal)
        imageView?.tintColor = color

        setTitleColor(.black, for: .normal)
        setTitle(title, for: .normal)
        configuration?.imagePadding = 8
    }
}
