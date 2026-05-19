import Combine
import UIKit

final class SignatureDisplaySegmentedSelectorView: UIControl, UIScrollViewDelegate {
    private var optionStackView: UIStackView = {
        let optionStackView = UIStackView()
        optionStackView.axis = .horizontal
        optionStackView.translatesAutoresizingMaskIntoConstraints = false
        return optionStackView
    }()
    private var optionScrollView: UIScrollView = {
        let optionScrollView = UIScrollView()
        optionScrollView.showsHorizontalScrollIndicator = false
        optionScrollView.translatesAutoresizingMaskIntoConstraints = false
        optionScrollView.decelerationRate = .fast
        optionScrollView.isPagingEnabled = true
        return optionScrollView
    }()
    private let shownLabel: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "shown"
        label.font = .systemFont(ofSize: 18)
        label.textAlignment = .center

        view.addSubview(label)

        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 170),
            view.heightAnchor.constraint(equalToConstant: 50),

            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        return view
    }()
    private let partialLabel: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "partial"
        label.font = .systemFont(ofSize: 18)
        label.textAlignment = .center

        view.addSubview(label)

        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 170),
            view.heightAnchor.constraint(equalToConstant: 50),

            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        return view
    }()
    private let hiddenLabel: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "hidden"
        label.font = .systemFont(ofSize: 18)
        label.textAlignment = .center

        view.addSubview(label)

        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 170),
            view.heightAnchor.constraint(equalToConstant: 50),

            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        return view
    }()

    private let innerShadowLayer = CAShapeLayer()
    private(set) var innerWhiteShadowLayer = CAShapeLayer()
    var dispatcher: PassthroughSubject<MemoHomeViewInput, Never>?

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        innerShadowLayer.removeFromSuperlayer()
        innerWhiteShadowLayer.removeFromSuperlayer()

        innerShadowLayer.frame = bounds
        innerWhiteShadowLayer.frame = bounds

        layer.cornerRadius = bounds.height * 0.5
        layer.addSublayer(innerShadowLayer)
        layer.addSublayer(innerWhiteShadowLayer)

        let path = UIBezierPath(roundedRect: bounds.insetBy(dx: -7, dy: -7), cornerRadius: bounds.height * 0.5)
        let cutout = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.height * 0.5).reversing()
        path.append(cutout)

        innerShadowLayer.cornerRadius = bounds.height * 0.5
        innerShadowLayer.shadowPath = path.cgPath
        innerShadowLayer.masksToBounds = true
        innerShadowLayer.shadowColor = UIColor.black.cgColor
        innerShadowLayer.shadowOffset = .init(width: -3, height: 3)
        innerShadowLayer.shadowOpacity = 0.12
        innerShadowLayer.shadowRadius = 4
        innerShadowLayer.fillRule = .evenOdd

        innerWhiteShadowLayer.cornerRadius = bounds.height * 0.5
        innerWhiteShadowLayer.shadowPath = path.cgPath
        innerWhiteShadowLayer.masksToBounds = true
        innerWhiteShadowLayer.shadowColor = UIColor.white.cgColor
        innerWhiteShadowLayer.shadowOffset = .init(width: 3, height: -3)
        innerWhiteShadowLayer.shadowRadius = 4
        innerWhiteShadowLayer.fillRule = .evenOdd
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true

        optionStackView.addArrangedSubview(shownLabel)
        optionStackView.addArrangedSubview(partialLabel)
        optionStackView.addArrangedSubview(hiddenLabel)

        optionScrollView.addSubview(optionStackView)
        addSubview(optionScrollView)
        optionScrollView.delegate = self
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            optionStackView.topAnchor.constraint(equalTo: optionScrollView.topAnchor),
            optionStackView.trailingAnchor.constraint(equalTo: optionScrollView.trailingAnchor),
            optionStackView.leadingAnchor.constraint(equalTo: optionScrollView.leadingAnchor),
            optionStackView.bottomAnchor.constraint(equalTo: optionScrollView.bottomAnchor),

            optionScrollView.topAnchor.constraint(equalTo: topAnchor),
            optionScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            optionScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            optionScrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            widthAnchor.constraint(equalToConstant: 170),
            heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        let pageWidth: CGFloat = 170
        let targetX = targetContentOffset.pointee.x
        let page = round(targetX / pageWidth)

        targetContentOffset.pointee.x = page * pageWidth

        if targetContentOffset.pointee.x == 0 {
            dispatcher?.send(.willSetSignatureDrawingDisplay(.shown))
        } else if targetContentOffset.pointee.x == 170 {
            dispatcher?.send(.willSetSignatureDrawingDisplay(.partial))
        } else {
            dispatcher?.send(.willSetSignatureDrawingDisplay(.hidden))
        }
    }

    func setDrawingDisplayOption(_ opt: DrawingDisplayOption) {
        switch opt {
            case .shown: optionScrollView.setContentOffset(.init(x: 0, y: 0), animated: false)
            case .partial: optionScrollView.setContentOffset(.init(x: 170, y: 0), animated: false)
            case .hidden: optionScrollView.setContentOffset(.init(x: 340, y: 0), animated: false)
        }
    }
}
