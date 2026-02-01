import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions
    ) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)

        DependencyConfigurator.configureDependencies()
        
        let memoHomeViewModel = DIContainer.shared.resolve(MemoHomeViewModel.self)
        let memoHomeViewController = MemoHomeViewController(memoHomeViewModel: memoHomeViewModel)
        let indexViewController = UINavigationController(rootViewController: memoHomeViewController)

        indexViewController.delegate = NavigationDelegateObject.shared
        indexViewController.navigationBar.isHidden = true

        window.rootViewController = indexViewController
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {}
}

protocol NavigationViewControllerDismissible {
    func onDismiss()
}

class NavigationDelegateObject: NSObject, UINavigationControllerDelegate {

    static var shared = NavigationDelegateObject()

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController, animated: Bool
    ) {

        if let fromViewController = navigationController.transitionCoordinator?.viewController(forKey: .from),
            !navigationController.viewControllers.contains(fromViewController)
        {
            if let popedViewController = fromViewController as? NavigationViewControllerDismissible {
                popedViewController.onDismiss()
            }
        }
    }
}
