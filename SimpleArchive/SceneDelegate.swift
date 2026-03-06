import Combine
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = HostUIWindow(windowScene: windowScene)

        DependencyConfigurator.configureDependencies()

        let memoHomeViewModel = DIContainer.shared.resolve(MemoHomeViewModel.self)
        let memoHomeViewController = MemoHomeViewController(memoHomeViewModel: memoHomeViewModel)
        let indexViewController = UINavigationController(rootViewController: memoHomeViewController)

        indexViewController.navigationBar.isHidden = true
        if #available(iOS 26.0, *) {
            indexViewController.interactiveContentPopGestureRecognizer?.isEnabled = false
        }

        window.rootViewController = indexViewController
        window.makeKeyAndVisible()
        window.bringSubviewToFront(window.audioControlBar)

        self.window = window
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {}
}
