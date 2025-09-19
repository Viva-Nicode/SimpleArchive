import UIKit

final class SliderView: UIView {

    private let containerStack: UIStackView = {
        let containerStack = UIStackView()
        containerStack.axis = .horizontal
        containerStack.spacing = 8
        containerStack.alignment = .center
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        return containerStack
    }()

    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = .black
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        return titleLabel
    }()

    let slider: UISlider = {
        let slider = UISlider()
        slider.minimumTrackTintColor = .systemBlue
        slider.maximumTrackTintColor = .systemGray3
        slider.setThumbImage(UIImage(systemName: "circle.fill"), for: .normal)
        return slider
    }()

    private let valueLabel: UILabel = {
        let valueLabel = UILabel()
        valueLabel.textColor = .black
        valueLabel.widthAnchor.constraint(equalToConstant: 34).isActive = true
        valueLabel.textAlignment = .right
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        return valueLabel
    }()

    init(titleText: String, minimum: Float, maximum: Float, initialValue: Float) {
        self.titleLabel.text = titleText
        self.slider.minimumValue = minimum
        self.slider.maximumValue = maximum
        self.slider.value = initialValue
        self.valueLabel.text = "\(Int(initialValue))"
        super.init(frame: .zero)
        containerStack.addArrangedSubview(titleLabel)
        containerStack.addArrangedSubview(slider)
        containerStack.setCustomSpacing(2, after: slider)
        containerStack.addArrangedSubview(valueLabel)

        addSubview(containerStack)

        NSLayoutConstraint.activate([
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStack.topAnchor.constraint(equalTo: topAnchor),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        slider.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                self.valueLabel.text = "\(Int(self.slider.value))"
            }, for: .valueChanged)
    }

    var getSliderValue: Int { Int(slider.value) }

    required init?(coder: NSCoder) { fatalError() }
}
