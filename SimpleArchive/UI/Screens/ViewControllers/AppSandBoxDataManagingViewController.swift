import Combine
import UIKit

final class AppSandBoxDataManagingViewController: UIViewController, UICollectionViewDelegateFlowLayout {
    typealias Input = AppSandBoxDataManagingViewModel.Action
    typealias Output = AppSandBoxDataManagingViewModel.Event

    private var input = PassthroughSubject<Input, Never>()
    private var viewModel: AppSandBoxDataManagingViewModel
    private var subscriptions = Set<AnyCancellable>()

    private var audioDataCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(
            AudioDataCollectionViewCell.self,
            forCellWithReuseIdentifier: AudioDataCollectionViewCell.reuseIdentifier)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    private var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        return textLabel
    }()

    init(viewModel: AppSandBoxDataManagingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
	
	deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        viewModel.subscribe(input: input.eraseToAnyPublisher())
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                    case .viewDidLoad(let audios, let total):
                        setupUI(audioDatas: audios, total: total)
                        setupConstraint()
                        setupAction()
                }
            }
            .store(in: &subscriptions)
        input.send(.viewDidLoad)
    }

    private var ds: AudioDataCollectionViewDataSource?

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: 120, height: 120)
    }

    private func setupUI(audioDatas: [AudioTrackMetadata], total: Int64) {
        view.backgroundColor = .systemBackground
        view.addSubview(textLabel)
        view.addSubview(audioDataCollectionView)
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file

        let totalSize = formatter.string(fromByteCount: total)
        textLabel.text = "total : \(totalSize)"

		audioDataCollectionView.backgroundColor = .clear

        ds = AudioDataCollectionViewDataSource(metadatas: audioDatas)
        audioDataCollectionView.dataSource = ds
        audioDataCollectionView.delegate = self
        audioDataCollectionView.reloadData()
    }

    private func setupConstraint() {
        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            textLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            audioDataCollectionView.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 20),
            audioDataCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            audioDataCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            audioDataCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupAction() {

    }
}

final class AudioDataCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "AudioDataCollectionViewCell"

    private var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        contentView.showMeBorder(.red)
        contentView.addSubview(titleLabel)
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            titleLabel.widthAnchor.constraint(equalToConstant: 120),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
        ])
    }

    func configure(data: AudioTrackMetadata) {
        titleLabel.text = data.title
    }
}

final class AudioDataCollectionViewDataSource: NSObject, UICollectionViewDataSource {
    var metadatas: [AudioTrackMetadata]

    init(metadatas: [AudioTrackMetadata]) {
        self.metadatas = metadatas
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        metadatas.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let audioData = metadatas[indexPath.row]

        let audioDataCell =
            collectionView.dequeueReusableCell(
                withReuseIdentifier: AudioDataCollectionViewCell.reuseIdentifier,
                for: indexPath) as! AudioDataCollectionViewCell

        audioDataCell.configure(data: audioData)

        return audioDataCell
    }
}
