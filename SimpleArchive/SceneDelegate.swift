import Combine
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UINavigationControllerDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = AudioControlBarHostWindow(windowScene: windowScene)

        DependencyConfigurator.configureDependencies()

        let memoHomeViewModel = DIContainer.shared.resolve(MemoHomeViewModel.self)
        let memoHomeViewController = MemoHomeViewController(
            memoHomeViewModel: memoHomeViewModel,
            audioControlBarHost: window)
        let indexViewController = UINavigationController(rootViewController: memoHomeViewController)
        indexViewController.delegate = self

        indexViewController.navigationBar.isHidden = true
        if #available(iOS 26.0, *) {
            indexViewController.interactiveContentPopGestureRecognizer?.isEnabled = false
        }

        window.rootViewController = indexViewController
        window.makeKeyAndVisible()

        self.window = window
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {}

    // 네비게이션vc에 특정 vc가 push될때 audioControlBar가 사라지게하고 pop될때 다시 나타나게 하기위한 함수
    func navigationController(
        _ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool
    ) {
        guard
            let hostWindow = window as? AudioControlBarHostWindow,
            let fromVC = navigationController.transitionCoordinator?.viewController(forKey: .from)
        else { return }

        let visibleControlBarVCTypes: [UIViewController.Type] = [
            MemoHomeViewController.self,
            MemoPageViewController.self,
            SingleAudioPageViewController.self,
            SingleTablePageViewController.self,
            SingleTextEditorPageViewController.self,
        ]

        let isFromVCInControlBarVisibleScope =
            visibleControlBarVCTypes
            .contains(where: { fromVC.isKind(of: $0) })
        let isToVCInControlBarVisibleScope =
            visibleControlBarVCTypes
            .contains(where: { viewController.isKind(of: $0) })
        let isActiveAudioControlBar = ![.initial, .stop].contains(hostWindow.audioControlBarState)

        if isToVCInControlBarVisibleScope && isActiveAudioControlBar {
            navigationController.transitionCoordinator?
                .animate(
                    alongsideTransition: { _ in
                        hostWindow.audioControlBar.isHidden = false
                        hostWindow.audioControlBar.alpha = 1
                    },
                    completion: { ctx in
                        if ctx.isCancelled && !isFromVCInControlBarVisibleScope {
                            hostWindow.audioControlBar.isHidden = true
                            hostWindow.audioControlBar.alpha = 0
                        }
                    }
                )
        } else {
            navigationController.transitionCoordinator?
                .animate(
                    alongsideTransition: { _ in
                        hostWindow.audioControlBar.alpha = 0
                    },
                    completion: { _ in
                        hostWindow.audioControlBar.isHidden = true
                    }
                )
        }
    }
}
