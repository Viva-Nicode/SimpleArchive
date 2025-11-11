import Combine
import UIKit

final class CreateNewComponentView: UIViewController {

    private let kindofAddableComponentItems: [ComponentType] = ComponentType.allCases

    private(set) var titleLabel: UILabel = {
        $0.text = "Create New Note"
        $0.font = .systemFont(ofSize: 22, weight: .regular)
        return $0
    }(UILabel())
    private let backgroundView: UIStackView = {
        let bg = UIStackView()
        bg.backgroundColor = .systemBackground
        bg.isLayoutMarginsRelativeArrangement = true
        bg.layoutMargins = .init(top: 20, left: 20, bottom: 0, right: 20)
        bg.axis = .vertical
        bg.translatesAutoresizingMaskIntoConstraints = false
        return bg
    }()
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    let componentTypePublisher = PassthroughSubject<ComponentType, Never>()

    deinit { print("deinit CreateNewComponentView") }

    override func viewDidLoad() {
        view.backgroundColor = .systemBackground
        view.addSubview(backgroundView)

        backgroundView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        backgroundView.addArrangedSubview(titleLabel)
        backgroundView.addArrangedSubview(collectionView)
        collectionView.backgroundColor = .clear
        collectionView.isPrefetchingEnabled = false

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ComponentItemView.self, forCellWithReuseIdentifier: ComponentItemView.reuseIdentifier)
    }
}

extension CreateNewComponentView: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        ComponentType.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let data = kindofAddableComponentItems[indexPath.item]

        let cell =
            collectionView.dequeueReusableCell(
                withReuseIdentifier: ComponentItemView.reuseIdentifier,
                for: indexPath
            ) as! ComponentItemView

        cell.configure(with: data)
        cell.setColorToBlue()
        return cell
    }
}

extension CreateNewComponentView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        componentTypePublisher.send(kindofAddableComponentItems[indexPath.item])
        dismiss(animated: true)
    }
}

extension CreateNewComponentView: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.frame.width / 3, height: collectionView.frame.width / 3)
    }

    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat { .zero }

    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat { .zero }
}
