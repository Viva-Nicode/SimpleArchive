import UIKit
import Combine

protocol CreateNewComponentViewDelegate: AnyObject {
    func createNewComponent(with: ComponentType)
}

class CreateNewComponentView: UIViewController {

    private var kindofAddableComponentItems: [ComponentType] = ComponentType.allCases
    weak var delegate: CreateNewComponentViewDelegate?

    private let backgroundView: UIStackView = {
        let bg = UIStackView()
        bg.backgroundColor = .systemBackground
        bg.axis = .vertical
        bg.translatesAutoresizingMaskIntoConstraints = false
        return bg
    }()
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()

    override func viewDidLoad() {

        view.backgroundColor = .systemBackground
        view.addSubview(backgroundView)

        backgroundView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        setupCollectionView()
    }

    private func setupCollectionView() {
        backgroundView.addArrangedSubview(collectionView)
        collectionView.backgroundColor = .clear
        collectionView.isPrefetchingEnabled = false

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor).isActive = true

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(AddableComponentItem.self, forCellWithReuseIdentifier: AddableComponentItem.reuseIdentifier)
    }
}

extension CreateNewComponentView: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        ComponentType.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let data = kindofAddableComponentItems[indexPath.item]

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: AddableComponentItem.reuseIdentifier,
            for: indexPath
        ) as! AddableComponentItem

        cell.configure(with: data)
        return cell
    }
}

class AddableComponentItem: UICollectionViewCell {

    static let reuseIdentifier = "AddableComponentItem"
    var kindOfItemType: ComponentType?

    var itemTitleLabel = UILabel()
    var itemSymbol = UIImageView()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 5
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentView.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20).isActive = true
        stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20).isActive = true
        stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
        stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true

        itemSymbol.contentMode = .scaleAspectFill
        stackView.addArrangedSubview(itemSymbol)
        stackView.addArrangedSubview(itemTitleLabel)
    }

    func configure(with: ComponentType) {
        itemSymbol.image = UIImage(systemName: with.getSymbolSystemName)
        itemTitleLabel.text = with.getTitle
    }
}

extension CreateNewComponentView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.createNewComponent(with: kindofAddableComponentItems[indexPath.item])
        self.dismiss(animated: true)
    }
}

extension CreateNewComponentView: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.width / 3, height: collectionView.frame.width / 3)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat { .zero }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat { .zero }
}

