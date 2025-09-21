import UIKit

extension CALayer {
    func addBorder(_ arr_edge: [UIRectEdge], color: UIColor, width: CGFloat) {
        for edge in arr_edge {
            let border = CALayer()
            switch edge {
                case UIRectEdge.top:
                    border.frame = CGRect.init(x: 0, y: 0, width: frame.width, height: width)
                    break
                case UIRectEdge.bottom:
                    border.frame = CGRect.init(x: 0, y: frame.height - width, width: frame.width, height: width)
                    break
                case UIRectEdge.left:
                    border.frame = CGRect.init(x: 0, y: 0, width: width, height: frame.height)
                    break
                case UIRectEdge.right:
                    border.frame = CGRect.init(x: frame.width - width, y: 0, width: width, height: frame.height)
                    break
                default:
                    break
            }
            border.backgroundColor = color.cgColor
            self.addSublayer(border)
        }
    }
}

extension UIScrollView {

    func scrollSubviewToCenter(_ subview: UIView, animated: Bool) {
        let targetFrame = subview.convert(subview.bounds, to: self)
        let centeredOffsetX = targetFrame.midX - self.bounds.width / 2
        let maxOffsetX = self.contentSize.width - self.bounds.width
        let minOffsetX: CGFloat = 0
        let finalOffsetX = max(min(centeredOffsetX, maxOffsetX), minOffsetX)
        let targetOffset = CGPoint(x: finalOffsetX, y: self.contentOffset.y)

        setContentOffset(targetOffset, animated: animated)
    }

    func scrollToBottom(animated: Bool) {

        let maxOffsetY = max(0, contentSize.height - bounds.height + contentInset.bottom)

        guard maxOffsetY > 0 else { return }

        setContentOffset(
            CGPoint(x: contentOffset.x, y: maxOffsetY),
            animated: animated
        )
    }

    func scrollToTrailing(animated: Bool) {
        let maxOffsetX = max(0, contentSize.width - bounds.width + contentInset.right)

        guard maxOffsetX > 0 else { return }

        setContentOffset(
            CGPoint(x: maxOffsetX, y: contentOffset.y),
            animated: animated
        )
    }
}

extension UIResponder {
    private weak static var _currentFirstResponder: UIResponder? = nil

    public static var current: UIResponder? {
        UIResponder._currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(findFirstResponder(sender:)), to: nil, from: nil, for: nil)
        return UIResponder._currentFirstResponder
    }

    @objc internal func findFirstResponder(sender: AnyObject) {
        UIResponder._currentFirstResponder = self
    }
}

extension UIView {
    func addBottomBorder(color: UIColor, thickness: CGFloat = 1.0) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(
            x: 0,
            y: self.bounds.height - thickness,
            width: self.bounds.width,
            height: thickness
        )
        self.layer.addSublayer(border)
    }
}

extension UIView {
    public static var spacerView: UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        view.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        return view
    }

    public static let screenHeight = UIScreen.main.bounds.height
    public static let screenWidth = UIScreen.main.bounds.width

    func showMeBorder(_ anyColor: BorderColor) {
        self.layer.borderWidth = 1
        self.layer.borderColor = anyColor.cgColor
    }

    enum BorderColor {

        case red
        case blue
        case green
        case purple

        var cgColor: CGColor {
            switch self {
                case .red: return UIColor.red.cgColor
                case .blue: return UIColor.blue.cgColor
                case .green: return UIColor.green.cgColor
                case .purple: return UIColor.purple.cgColor
            }
        }
    }
}

extension Date {
    var formattedDate: String {
        let myDateFormatter = DateFormatter()
        myDateFormatter.dateFormat = "yyyy.MM.dd a hh:mm:ss"
        let convertStr = myDateFormatter.string(from: self)
        return convertStr
    }
}

enum UIConstants {
    static let componentMinimumHeight: CGFloat = 65.0
    static let tableComponentCellMaximumWidth: CGFloat = 260.0

    enum TableComponentCellEditPopupViewConstants {
        static let rowElementWidth: CGFloat = ((UIView.screenWidth * 0.8) - 40) / 3
        static let editingSeparatorLineHeight: CGFloat = 25
    }
}
