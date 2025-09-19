import Combine
import UIKit

final class TableComponentCellEditPopupView: PopupView {
    private(set) var titleLabelContainer: UIStackView = {
        let titleLabelContainer = UIStackView()
        titleLabelContainer.axis = .horizontal
        titleLabelContainer.alignment = .center
        titleLabelContainer.spacing = 4
        return titleLabelContainer
    }()
    private(set) var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "Edit Cell"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .black
        return titleLabel
    }()
    private(set) var rowStackView: UIStackView = {
        let rowStackView = UIStackView()
        rowStackView.axis = .horizontal
        rowStackView.spacing = 8
        rowStackView.alignment = .top
        rowStackView.isLayoutMarginsRelativeArrangement = true
        rowStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0,
            leading: UIConstants.TableComponentCellEditPopupViewConstants.rowElementWidth,
            bottom: 0,
            trailing: UIConstants.TableComponentCellEditPopupViewConstants.rowElementWidth)
        rowStackView.translatesAutoresizingMaskIntoConstraints = false
        return rowStackView
    }()
    private(set) var rowScrollView: UIScrollView = {
        let rowScrollView = UIScrollView()
        rowScrollView.showsHorizontalScrollIndicator = false
        rowScrollView.translatesAutoresizingMaskIntoConstraints = false
        rowScrollView.layer.cornerRadius = 7
        rowScrollView.backgroundColor = .init(named: "MyLightGray")
        rowScrollView.contentInset = .init(top: 8, left: 8, bottom: 8, right: 8)
        return rowScrollView
    }()
    private(set) var accessionalButtonsStackView: UIStackView = {
        let optionButtonContainerStackView = UIStackView()
        optionButtonContainerStackView.axis = .horizontal
        optionButtonContainerStackView.spacing = 8
        return optionButtonContainerStackView
    }()
    private(set) var removeRowButton: UIButton = {
        let removeRowButton = UIButton()
        removeRowButton.setImage(UIImage(systemName: "minus.circle"), for: .normal)
        removeRowButton.tintColor = .systemGray3
        return removeRowButton
    }()
    private(set) var pasteButton: UIButton = {
        let pasteButton = UIButton()
        pasteButton.setImage(UIImage(systemName: "document.fill"), for: .normal)
        pasteButton.tintColor = .systemGray3
        return pasteButton
    }()
    private(set) var randomStringButton: UIButton = {
        let randomStringButton = UIButton()
        randomStringButton.setImage(UIImage(systemName: "doc.questionmark.fill.rtl"), for: .normal)
        randomStringButton.tintColor = .systemGray3
        return randomStringButton
    }()
    private(set) var tableComponentCellValueTextView: UITextView = {
        let tableComponentCellValueTextView = UITextView(usingTextLayoutManager: false)
        tableComponentCellValueTextView.textContainerInset = .init(top: 10, left: 10, bottom: 10, right: 10)
        tableComponentCellValueTextView.autocorrectionType = .no
        tableComponentCellValueTextView.spellCheckingType = .no
        tableComponentCellValueTextView.autocapitalizationType = .none
        tableComponentCellValueTextView.backgroundColor = .init(named: "MyLightGray")
        tableComponentCellValueTextView.textColor = .black
        tableComponentCellValueTextView.font = .systemFont(ofSize: 15)
        tableComponentCellValueTextView.translatesAutoresizingMaskIntoConstraints = false
        tableComponentCellValueTextView.layer.cornerRadius = 7
        return tableComponentCellValueTextView
    }()
    private(set) var buttonContainerStackView: UIStackView = {
        let buttonContainerStackView = UIStackView()
        buttonContainerStackView.axis = .horizontal
        buttonContainerStackView.spacing = 8
        buttonContainerStackView.alignment = .center
        buttonContainerStackView.distribution = .fillEqually
        return buttonContainerStackView
    }()
    private(set) var confirmButton: UIButton = {
        let confirmButton = UIButton()
        confirmButton.backgroundColor = .systemBlue
        confirmButton.tintColor = .white
        confirmButton.layer.cornerRadius = 5
        confirmButton.configuration = .plain()
        confirmButton.configuration?.contentInsets = NSDirectionalEdgeInsets(
            top: 12, leading: 0, bottom: 12, trailing: 0)

        var titleAttr = AttributedString.init("Save")
        titleAttr.font = .systemFont(ofSize: 15, weight: .regular)
        confirmButton.configuration?.attributedTitle = titleAttr

        return confirmButton
    }()
    private(set) var cancelButton: UIButton = {
        let cancelButton = UIButton()
        cancelButton.backgroundColor = .systemPink
        cancelButton.tintColor = .white
        cancelButton.layer.cornerRadius = 5
        cancelButton.configuration = .plain()
        cancelButton.configuration?.contentInsets = NSDirectionalEdgeInsets(
            top: 12, leading: 0, bottom: 12, trailing: 0)

        var titleAttr = AttributedString.init("Cancel")
        titleAttr.font = .systemFont(ofSize: 15, weight: .regular)
        cancelButton.configuration?.attributedTitle = titleAttr

        return cancelButton
    }()

    // MARK: - Random Text Generating Views
    private(set) var randomTextGenerateTitleLabel: UILabel = {
        let randomTextGenerateTitleLabel = UILabel()
        randomTextGenerateTitleLabel.text = "Random Text Generate"
        randomTextGenerateTitleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        randomTextGenerateTitleLabel.textColor = .black
        randomTextGenerateTitleLabel.isHidden = true
        randomTextGenerateTitleLabel.alpha = 0
        return randomTextGenerateTitleLabel
    }()
    private(set) var textLengthSlider: SliderView = {
        let textLengthSlider = SliderView(titleText: "text Length", minimum: 8, maximum: 32, initialValue: 8)
        textLengthSlider.isHidden = true
        textLengthSlider.alpha = 0
        return textLengthSlider
    }()
    private(set) var checkBoxes: [CheckboxButton] = [
        CheckboxButton(title: "alphabet lowercase letter"),
        CheckboxButton(title: "alphabet capital letter"),
        CheckboxButton(title: "number"),
        CheckboxButton(title: "special character"),
    ]
    private(set) var checkBoxContainer: UIStackView = {
        let checkBoxContainer = UIStackView()
        checkBoxContainer.axis = .vertical
        checkBoxContainer.alignment = .leading
        checkBoxContainer.spacing = 0
        checkBoxContainer.isHidden = true
        checkBoxContainer.alpha = 0
        return checkBoxContainer
    }()
    private(set) var allOptionCheckLabel: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("all", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15)
        button.isHidden = true
        button.alpha = 0
        return button
    }()
    private(set) var randomTextGenerateConfirmationButtonContainer: UIStackView = {
        let randomTextGenerateConfirmationButtonContainer = UIStackView()
        randomTextGenerateConfirmationButtonContainer.axis = .horizontal
        randomTextGenerateConfirmationButtonContainer.spacing = 8
        randomTextGenerateConfirmationButtonContainer.alignment = .center
        randomTextGenerateConfirmationButtonContainer.distribution = .fillEqually
        randomTextGenerateConfirmationButtonContainer.isHidden = true
        randomTextGenerateConfirmationButtonContainer.alpha = 0
        return randomTextGenerateConfirmationButtonContainer
    }()
    private(set) var generateConfirmButton: UIButton = {
        let generateConfirmButton = UIButton()
        generateConfirmButton.backgroundColor = .systemBlue
        generateConfirmButton.tintColor = .white
        generateConfirmButton.layer.cornerRadius = 5
        generateConfirmButton.configuration = .plain()
        generateConfirmButton.configuration?.contentInsets = NSDirectionalEdgeInsets(
            top: 12, leading: 0, bottom: 12, trailing: 0)

        var titleAttr = AttributedString.init("Generate")
        titleAttr.font = .systemFont(ofSize: 15, weight: .regular)
        generateConfirmButton.configuration?.attributedTitle = titleAttr

        return generateConfirmButton
    }()
    private(set) var generateCancelButton: UIButton = {
        let generateCancelButton = UIButton()
        generateCancelButton.backgroundColor = .systemPink
        generateCancelButton.tintColor = .white
        generateCancelButton.layer.cornerRadius = 5
        generateCancelButton.configuration = .plain()
        generateCancelButton.configuration?.contentInsets = NSDirectionalEdgeInsets(
            top: 12, leading: 0, bottom: 12, trailing: 0)

        var titleAttr = AttributedString.init("Cancel")
        titleAttr.font = .systemFont(ofSize: 15, weight: .regular)
        generateCancelButton.configuration?.attributedTitle = titleAttr

        return generateCancelButton
    }()

    private var columnTitles: [String]
    private var cellValues: [String]
    private var cellIndex: Int
    private var rowIndex: Int
    private let columnTitleFont = UIFont.systemFont(ofSize: 16)
    private let cellValueFont = UIFont.systemFont(ofSize: 15, weight: .thin)
    private let separatorLineHieght: CGFloat = 1
    private let editingCellSeparatorView = EditingCellSeparatorView()
    private var randomTextGenerator = RandomTextGenerator()

    var confirmButtonPublisher: AnyPublisher<String, Never> {
        confirmButton
            .throttleTapPublisher()
            .map { _ in
                self.dismiss()
                return self.tableComponentCellValueTextView.text!
            }
            .eraseToAnyPublisher()
    }

    var removeRowButtonPublisher: AnyPublisher<Void, Never> {
        removeRowButton
            .throttleTapPublisher()
            .map { _ in self.dismiss() }
            .eraseToAnyPublisher()
    }

    init(
        columnTitles: [String],
        cellValues: [String],
        cellIndex: Int,
        rowIndex: Int
    ) {
        self.columnTitles = columnTitles
        self.cellValues = cellValues
        self.cellIndex = cellIndex
        self.rowIndex = rowIndex
        self.tableComponentCellValueTextView.text = cellValues[cellIndex]
        super.init()
    }

    deinit { print("deinit TableComponentCellEditPopupView") }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            tableComponentCellValueTextView.becomeFirstResponder()
        } else {
            tableComponentCellValueTextView.resignFirstResponder()
        }
    }

    override func popupViewDetailConfigure() {

        titleLabelContainer.addArrangedSubview(titleLabel)
        titleLabelContainer.addArrangedSubview(randomTextGenerateTitleLabel)
        alertContainer.addArrangedSubview(titleLabelContainer)

        var columnTitleLabelMaximumHeight: CGFloat = .zero
        var cellValueLabelMaximumHeight: CGFloat = .zero

        for (index, (columnTitle, cellValue)) in zip(columnTitles, cellValues).enumerated() {
            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.spacing = 4
            stackView.alignment = .center

            if index == cellIndex {
                stackView.addArrangedSubview(editingCellSeparatorView)
            } else {
                let paddingView = UIView()
                paddingView.translatesAutoresizingMaskIntoConstraints = false
                stackView.addArrangedSubview(paddingView)
                paddingView.widthAnchor.constraint(equalToConstant: 80).isActive = true
                paddingView.heightAnchor
                    .constraint(
                        equalToConstant: UIConstants.TableComponentCellEditPopupViewConstants.editingSeparatorLineHeight
                    )
                    .isActive = true
            }

            let columnTitleLabel = UILabel()
            columnTitleLabel.textAlignment = .left
            let colHeight =
                self.boundingSize(
                    for: columnTitle,
                    width: UIConstants.TableComponentCellEditPopupViewConstants.rowElementWidth,
                    font: columnTitleFont,
                    lineLimit: 3
                )
                .height
            columnTitleLabelMaximumHeight = max(columnTitleLabelMaximumHeight, colHeight)
            columnTitleLabel.text = columnTitle
            columnTitleLabel.numberOfLines = 1
            columnTitleLabel.font = columnTitleFont
            columnTitleLabel.textColor = .black

            let separator = UIView()
            separator.backgroundColor = index == cellIndex ? .systemBlue : .lightGray

            separator.translatesAutoresizingMaskIntoConstraints = false
            separator.heightAnchor.constraint(equalToConstant: separatorLineHieght).isActive = true
            separator.widthAnchor.constraint(equalToConstant: 65).isActive = true

            let cellValueLabel = UILabel()
            cellValueLabel.textAlignment = .left
            cellValueLabel.text = cellValue.isEmpty ? "empty" : cellValue
            cellValueLabel.textColor = cellValue.isEmpty ? .systemGray2 : .label

            let cellHeight =
                self.boundingSize(
                    for: cellValue,
                    width: UIConstants.TableComponentCellEditPopupViewConstants.rowElementWidth,
                    font: cellValueFont,
                    lineLimit: 3
                )
                .height
            cellValueLabelMaximumHeight = max(cellValueLabelMaximumHeight, cellHeight)
            cellValueLabel.numberOfLines = 3
            cellValueLabel.font = cellValueFont
            cellValueLabel.textColor = .black

            stackView.translatesAutoresizingMaskIntoConstraints = false

            stackView.addArrangedSubview(columnTitleLabel)
            stackView.addArrangedSubview(separator)
            stackView.addArrangedSubview(cellValueLabel)

            rowStackView.addArrangedSubview(stackView)
            stackView.widthAnchor
                .constraint(equalToConstant: UIConstants.TableComponentCellEditPopupViewConstants.rowElementWidth)
                .isActive = true
        }

        rowScrollView.addSubview(rowStackView)
        alertContainer.addArrangedSubview(rowScrollView)

        let rowScrollVieHheight =
            columnTitleLabelMaximumHeight + cellValueLabelMaximumHeight
            + UIConstants.TableComponentCellEditPopupViewConstants.editingSeparatorLineHeight + 4 * 3
            + separatorLineHieght + 16

        NSLayoutConstraint.activate([
            rowScrollView.heightAnchor.constraint(equalToConstant: rowScrollVieHheight),

            rowStackView.topAnchor.constraint(equalTo: rowScrollView.topAnchor),
            rowStackView.bottomAnchor.constraint(equalTo: rowScrollView.bottomAnchor),
            rowStackView.leadingAnchor.constraint(equalTo: rowScrollView.leadingAnchor),
            rowStackView.trailingAnchor.constraint(equalTo: rowScrollView.trailingAnchor),

            tableComponentCellValueTextView.heightAnchor.constraint(equalToConstant: 120),
        ])

        let lineLabel = UILabel()
        lineLabel.text = "\(rowIndex)번째 행"
        lineLabel.textColor = .black
        accessionalButtonsStackView.addArrangedSubview(lineLabel)
        accessionalButtonsStackView.addArrangedSubview(UIView.spacerView)

        accessionalButtonsStackView.addArrangedSubview(removeRowButton)

        accessionalButtonsStackView.addArrangedSubview(pasteButton)
        pasteButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                if let string = UIPasteboard.general.string {
                    tableComponentCellValueTextView.text = string
                }
            }, for: .touchUpInside)

        accessionalButtonsStackView.addArrangedSubview(randomStringButton)
        randomStringButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                transitionRandomTextGenerateView()
                tableComponentCellValueTextView.resignFirstResponder()
            }, for: .touchUpInside)

        alertContainer.addArrangedSubview(accessionalButtonsStackView)
        alertContainer.setCustomSpacing(2, after: accessionalButtonsStackView)

        alertContainer.addArrangedSubview(tableComponentCellValueTextView)

        buttonContainerStackView.addArrangedSubview(cancelButton)
        cancelButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                dismiss()
            }, for: .touchUpInside)

        buttonContainerStackView.addArrangedSubview(confirmButton)

        alertContainer.addArrangedSubview(buttonContainerStackView)
        setupRandomTextGenerateView()

        layoutIfNeeded()

        rowScrollView.scrollSubviewToCenter(rowStackView.arrangedSubviews[cellIndex], animated: true)
    }

    private func setupRandomTextGenerateView() {
        alertContainer.addArrangedSubview(textLengthSlider)
        checkBoxes.forEach { checkBoxContainer.addArrangedSubview($0) }

        alertContainer.addArrangedSubview(checkBoxContainer)
        alertContainer.setCustomSpacing(0, after: checkBoxContainer)

        textLengthSlider.slider.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                randomTextGenerator.setTextLength(textLengthSlider.getSliderValue)
                updateGenerateConfirmButtonState()
            }, for: .valueChanged)

        checkBoxes[0]
            .addAction(
                UIAction { [weak self] _ in
                    guard let self else { return }
                    randomTextGenerator.toggleOption(for: .alphabetLowercaseLetter)
                    updateGenerateConfirmButtonState()
                }, for: .touchUpInside)

        checkBoxes[1]
            .addAction(
                UIAction { [weak self] _ in
                    guard let self else { return }
                    randomTextGenerator.toggleOption(for: .alphabetCapitalLetter)
                    updateGenerateConfirmButtonState()
                }, for: .touchUpInside)

        checkBoxes[2]
            .addAction(
                UIAction { [weak self] _ in
                    guard let self else { return }
                    randomTextGenerator.toggleOption(for: .number)
                    updateGenerateConfirmButtonState()
                }, for: .touchUpInside)

        checkBoxes[3]
            .addAction(
                UIAction { [weak self] _ in
                    guard let self else { return }
                    randomTextGenerator.toggleOption(for: .specialCharacter)
                    updateGenerateConfirmButtonState()
                }, for: .touchUpInside)

        alertContainer.addArrangedSubview(allOptionCheckLabel)

        allOptionCheckLabel.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                checkBoxes.forEach { $0.sendActions(for: .touchUpInside) }
                updateGenerateConfirmButtonState()
            }, for: .touchUpInside)

        randomTextGenerateConfirmationButtonContainer.addArrangedSubview(generateCancelButton)
        randomTextGenerateConfirmationButtonContainer.addArrangedSubview(generateConfirmButton)

        generateCancelButton.addAction(
            UIAction { _ in
                self.transitionRandomTextGenerateView()
                self.tableComponentCellValueTextView.becomeFirstResponder()
            }, for: .touchUpInside)

        generateConfirmButton.addAction(
            UIAction { _ in
                self.transitionRandomTextGenerateView()
                self.tableComponentCellValueTextView.becomeFirstResponder()
                let randomText = self.randomTextGenerator.getRandomText()
                self.tableComponentCellValueTextView.text = randomText
            }, for: .touchUpInside)

        alertContainer.addArrangedSubview(randomTextGenerateConfirmationButtonContainer)
        updateGenerateConfirmButtonState()
    }

    private func updateGenerateConfirmButtonState() {
        let sliderOK = textLengthSlider.getSliderValue > 0
        let anyChecked = checkBoxes.contains { $0.isChecked }
        generateConfirmButton.isEnabled = sliderOK && anyChecked
        generateConfirmButton.backgroundColor = sliderOK && anyChecked ? .systemBlue : .lightGray
    }

    private func transitionRandomTextGenerateView() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self else { return }

            [
                rowScrollView, accessionalButtonsStackView,
                tableComponentCellValueTextView,
                buttonContainerStackView, titleLabel,

                randomTextGenerateTitleLabel, allOptionCheckLabel,
                checkBoxContainer, textLengthSlider, randomTextGenerateConfirmationButtonContainer,
            ]
            .forEach {
                $0.isHidden.toggle()
                $0.alpha = $0.alpha == 0 ? 1 : 0
            }
        }
    }

    private func boundingSize(for text: String, width: CGFloat, font: UIFont, lineLimit: Int) -> CGSize {
        let nsText = text as NSString

        let boundingRect = nsText.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )

        let lineHeight = font.lineHeight
        let maxHeight = lineHeight * CGFloat(lineLimit)
        let limitedHeight = min(boundingRect.height, maxHeight)

        return CGSize(width: ceil(boundingRect.width), height: ceil(limitedHeight))
    }

}
