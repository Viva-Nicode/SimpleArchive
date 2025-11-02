import UIKit

class DynamicBackgrounColordButton: UIButton {

    enum ButtonState {
        case normal
        case disabled
    }

    private var disabledBackgroundColor: UIColor?
    private var defaultBackgroundColor: UIColor? {
        didSet { backgroundColor = defaultBackgroundColor }
    }

    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                if let color = defaultBackgroundColor {
                    self.backgroundColor = color
                    
                }
            } else {
                if let color = disabledBackgroundColor {
                    self.backgroundColor = color
                    
                }
            }
        }
    }

    func setBackgroundColor(_ color: UIColor?, for state: ButtonState) {
        switch state {
        case .disabled:
            disabledBackgroundColor = color

        case .normal:
            defaultBackgroundColor = color
        }
    }
}
