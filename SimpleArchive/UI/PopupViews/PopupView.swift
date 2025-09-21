import UIKit
import Combine

protocol PopupViewDetailConfigurable {
    func popupViewDetailConfigure()
}

class PopupView: UIView, PopupViewDetailConfigurable {

    var subscriptions: Set<AnyCancellable> = []

    let backgroundView: UIView = {
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        return backgroundView
    }()

    let alertContainer: UIStackView = {
        let alertContainer = UIStackView()
        alertContainer.isLayoutMarginsRelativeArrangement = true
        alertContainer.layoutMargins = .init(top: 20, left: 20, bottom: 20, right: 20)
        alertContainer.axis = .vertical
        alertContainer.spacing = 20
        alertContainer.backgroundColor = .white
        alertContainer.layer.cornerRadius = 10
        alertContainer.translatesAutoresizingMaskIntoConstraints = false
        return alertContainer
    }()

    private var centerYConstraint: NSLayoutConstraint!

    init() {
        super.init(frame: .zero)
        setupUI()
        setupKeyboardObservers()
        popupViewDetailConfigure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func popupViewDetailConfigure() { fatalError("This method must be overridden by subclass") }

    private func setupUI() {
        addSubview(backgroundView)
        addSubview(alertContainer)

        backgroundView.throttleUIViewTapGesturePublisher()
            .sink(receiveValue: { _ in self.dismiss() })
            .store(in: &subscriptions)

        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        alertContainer.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        centerYConstraint = alertContainer.centerYAnchor.constraint(equalTo: centerYAnchor)
        centerYConstraint.isActive = true
        alertContainer.widthAnchor.constraint(equalToConstant: UIView.screenWidth * 0.8).isActive = true
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                      let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
                else { return }

                let keyboardHeight = keyboardFrame.height
                self.centerYConstraint.constant = -(keyboardHeight / 3)

                UIView.animate(withDuration: duration) {
                    self.layoutIfNeeded()
                }
            }
            .store(in: &subscriptions)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
                else { return }

                self.centerYConstraint.constant = 0
                UIView.animate(withDuration: duration) {
                    self.layoutIfNeeded()
                }
            }
            .store(in: &subscriptions)
    }

    public func show() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            self.frame = window.bounds
            window.addSubview(self)

            self.alpha = 0
            self.alertContainer.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            UIView.animate(withDuration: 0.3) {
                self.alpha = 1
                self.alertContainer.transform = .identity
            }
        }
    }

    public func dismiss() {
        UIView.animate(withDuration: 0.2, animations: { self.alpha = 0 }) { _ in
            self.removeFromSuperview()
            self.subscriptions.removeAll()
        }
    }
}
