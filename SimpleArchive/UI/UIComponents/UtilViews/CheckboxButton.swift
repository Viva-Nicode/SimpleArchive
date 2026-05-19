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
        configuration?.contentInsets = .zero
		tintColor = .label
        addTarget(self, action: #selector(toggle), for: .touchUpInside)
        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func toggle() { isChecked.toggle() }

    private func updateAppearance() {
        let name = isChecked ? "checkmark.square.fill" : "square"
        let image = UIImage(systemName: name)?.withRenderingMode(.alwaysTemplate)
        setImage(image, for: .normal)
        setTitle(title, for: .normal)
        configuration?.imagePadding = 8
    }
}
