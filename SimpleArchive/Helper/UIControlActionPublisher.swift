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

        func request(_ demand: Subscribers.Demand) {}

        func cancel() { subscriber = nil }

        @objc func eventHandler() {
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

        func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure, Control == S.Input {
            let subscription = GestureSubscription(subscriber: subscriber, control: control, event: controlEvent)
            subscriber.receive(subscription: subscription)
        }
    }

    func throttleTapPublisher(interval: Double = 1.0)
        -> Publishers.Throttle<UIControl.GestruePublisher<UIControl>, RunLoop>
    {
        GestruePublisher(control: self, event: .touchUpInside)
            .throttle(for: .seconds(interval), scheduler: RunLoop.main, latest: false)
    }
}

extension UITapGestureRecognizer {

    final class UIViewTabSubscription<S: Subscriber, TapRecognizer: UITapGestureRecognizer>: Subscription
    where S.Input == TapRecognizer {

        private var subscriber: S?
        private let recognizer: TapRecognizer

        init(recognizer: TapRecognizer, subscriber: S, view: UIView) {
            self.recognizer = recognizer
            self.subscriber = subscriber
            self.recognizer.addTarget(self, action: #selector(tapGestureHandler))
            view.addGestureRecognizer(self.recognizer)
        }

        func request(_ demand: Subscribers.Demand) {}

        func cancel() { subscriber = nil }

        @objc func tapGestureHandler() {
            _ = subscriber?.receive(recognizer)
        }
    }

    struct UIViewTapPublisher<TapRecognizer: UITapGestureRecognizer>: Publisher {

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
    func throttleUIViewTapGesturePublisher(interval: Double = 1.0)
        -> Publishers.Throttle<UITapGestureRecognizer.UIViewTapPublisher<UITapGestureRecognizer>, RunLoop>
    {
        UITapGestureRecognizer.UIViewTapPublisher(recognizer: .init(), view: self)
            .throttle(for: .seconds(interval), scheduler: RunLoop.main, latest: false)
    }
}
