import Combine
import UIKit

extension UIControl {

    final class GestureSubscription<S: Subscriber, Control: UIControl>: Subscription where S.Input == Control {

        private var subscriber: S?
        private let control: Control

        init(subscriber: S, control: Control, event: UIControl.Event) {
            self.subscriber = subscriber
            self.control = control
            control.addTarget(self, action: #selector(eventHandler), for: event)
        }

        // 구독자가 발행자에게 값을 달라고할 때 구독자가 사용하는 함수
        func request(_ demand: Subscribers.Demand) { }

        // AnyCancelable을 구현해야 한다.
        func cancel() { subscriber = nil }

        @objc func eventHandler() {
            // 발행자가 어떤 값을 발행했을 때 구독자가 그 값을 처리하는 함수
            // 여기서 발행하는 값의 타입은 UIControl인데 어차피 faltMap으로 바꿔치기 하니까 값 자체는 큰 의미가 없고
            // 버튼이 탭되었을 때 값이 발행되고 sink(receiveValue:)가 실행된다는 사실이 중요한듯
            _ = subscriber?.receive(control)
        }
    }

    struct GestruePublisher<Control: UIControl>: Publisher {
        typealias Output = Control
        typealias Failure = Never

        private let control: Control
        private let controlEvent: UIControl.Event

        init(control: Control, event: UIControl.Event) {
            self.control = control
            self.controlEvent = event
        }

        // 어떤 subscriber가 해당 퍼블리셔를 구독했을 때 실행되는 함수
        // subscription을 생성하여 구독한 subscriber에게 receive(subscription:)함수를 통해 전달하는 역할을 한다.
        func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure, Control == S.Input {
            let subscription = GestureSubscription(subscriber: subscriber, control: control, event: controlEvent)
            subscriber.receive(subscription: subscription)
        }
    }

    func throttleTapPublisher(interval: Double = 1.0) -> Publishers.Throttle<UIControl.GestruePublisher<UIControl>, RunLoop> {
        GestruePublisher(control: self, event: .touchUpInside)
            .throttle(for: .seconds(interval), scheduler: RunLoop.main, latest: false)
    }
}

extension UITapGestureRecognizer {

    final class UIViewTabSubscription<S: Subscriber, TapRecognizer: UITapGestureRecognizer>: Subscription where S.Input == TapRecognizer {

        private var subscriber: S?
        private let recognizer: TapRecognizer

        init(recognizer: TapRecognizer, subscriber: S, view: UIView) {
            self.recognizer = recognizer
            self.subscriber = subscriber
            self.recognizer.addTarget(self, action: #selector(tapGestureHandler))
            view.addGestureRecognizer(self.recognizer)
        }

        // 원래는 request(_ demand: Subscribers.Demand)함수의 안에 subscriber?.receive()를 적어야하는게 일반적인것 같다.
        // 값을 주고받는 시점은 자유롭다.
        // 예를 들면 구독자가 값을 달라고했을 때 줄수도있고, 달라고 하지 않아도 그냥 줄수도있고.
        // 현재 코드 경우에는 값을 달라고 하든 달라고 하지않든 안주다가 버튼 이벤트가 발생하면 준다.
        func request(_ demand: Subscribers.Demand) {
//            _ = subscriber?.receive(recognizer)
        }

        func cancel() { subscriber = nil }

        @objc func tapGestureHandler() {
            _ = subscriber?.receive(recognizer)
        }
    }

    struct UIViewTapPublisher<TapRecognizer:UITapGestureRecognizer>: Publisher {

        typealias Output = TapRecognizer
        typealias Failure = Never

        private let recognizer: Output
        private let view: UIView

        init(recognizer: Output, view: UIView) {
            self.recognizer = recognizer
            self.view = view
        }

        func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure, TapRecognizer == S.Input {
            let subscription = UIViewTabSubscription(recognizer: recognizer, subscriber: subscriber, view: view)
            subscriber.receive(subscription: subscription)
        }
    }
}

extension UIView {
    func throttleUIViewTapGesturePublisher(interval: Double = 1.0) -> Publishers.Throttle<UITapGestureRecognizer.UIViewTapPublisher<UITapGestureRecognizer>, RunLoop> {
        UITapGestureRecognizer.UIViewTapPublisher(recognizer: .init(), view: self)
            .throttle(for: .seconds(interval), scheduler: RunLoop.main, latest: false)
    }
}
