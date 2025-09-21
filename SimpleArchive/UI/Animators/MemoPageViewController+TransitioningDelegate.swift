import UIKit

extension MemoPageViewController: UIViewControllerTransitioningDelegate {

    func animationController(
        forPresented presented: UIViewController, presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        ComponentFullScreenViewAnimator(
            type: .present,
            firstViewController: (presenting as! UINavigationController).topViewController
                as! MemoPageViewController,
            secondViewController: presented as! any ComponentFullScreenViewType)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let secondViewController = dismissed as? (any ComponentFullScreenViewType)
        else { return nil }
        return ComponentFullScreenViewAnimator(
            type: .dismiss,
            firstViewController: self,
            secondViewController: secondViewController)
    }
}
