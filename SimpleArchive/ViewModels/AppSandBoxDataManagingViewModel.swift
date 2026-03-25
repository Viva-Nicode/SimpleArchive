import Combine
import Foundation

final class AppSandBoxDataManagingViewModel {
    private var output = PassthroughSubject<Event, Never>()
    private var subscriptions = Set<AnyCancellable>()
    private let dataManager = AppSandBoxDataManager()

    deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }

    func subscribe(input: AnyPublisher<Action, Never>) -> AnyPublisher<Event, Never> {
        input.sink { [weak self] event in
            guard let self else { return }
            switch event {
                case .viewDidLoad:
                    let audios = dataManager.readAllAudioMetadata()
                    let audioTotal = dataManager.totalAudioFileSize()
                    output.send(.viewDidLoad(audios, audioTotal))
            }
        }
        .store(in: &subscriptions)

        return output.eraseToAnyPublisher()
    }

    enum Action {
        case viewDidLoad
    }

    enum Event {
        case viewDidLoad([AudioTrackMetadata], Int64)
    }
}
