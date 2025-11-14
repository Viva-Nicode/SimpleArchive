import UIKit

extension UIColor {
    var toHexString: String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }

        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)

        return String(format: "#%02X%02X%02X", r, g, b)
    }

    convenience init?(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

extension UIImage {
    var audioTrackThumbnailSquared: UIImage? {
        guard let cgImage = cgImage else { return nil }
        let length = min(cgImage.width, cgImage.height)
        let x = cgImage.width / 2 - length / 2
        let y = cgImage.height / 2 - length / 2
        let cropRect = CGRect(x: x, y: y, width: length, height: length)

        guard let croppedCGImage = cgImage.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: croppedCGImage, scale: scale, orientation: imageOrientation)
    }

    func blurred(radius: CGFloat) -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }

        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)

        guard let outputImage = filter?.outputImage else { return nil }

        let context = CIContext()
        let rect = CGRect(origin: .zero, size: size)
        if let cgImage = context.createCGImage(outputImage, from: rect) {
            return UIImage(cgImage: cgImage)
        }

        return nil
    }

    func resized(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage ?? self
    }
}

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

    var parentViewController: UIViewController? {
        var responder: UIResponder? = self

        while let next = responder?.next {
            if let vc = next as? UIViewController {
                return vc
            }
            responder = next
        }

        guard var top = window?.rootViewController else { return nil }
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
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
    static let componentMinimumHeight: CGFloat = 70.0
    static let tableComponentCellMaximumWidth: CGFloat = 260.0
    static let audioControlBarViewWidth: CGFloat = 330.0
    static let audioControlBarViewHeight: CGFloat = 140.0
    static let audioControlBarViewThumbnailWidth: CGFloat = 110.0

    static let singleAudioViewControllerTableViewFooterHeight: CGFloat = 160.0

    static let memoPageViewControllerCollectionViewFooterHeight = 200.0
    static let memoPageViewControllerCollectionViewHeaderHeight = 80.0
    static let memoPageViewControllerCollectionViewCellSpacing = 25.0

    enum TableComponentCellEditPopupViewConstants {
        static let rowElementWidth: CGFloat = ((UIView.screenWidth * 0.8) - 40) / 3
        static let editingSeparatorLineHeight: CGFloat = 25
    }
}
