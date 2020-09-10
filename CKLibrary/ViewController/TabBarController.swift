//
//  TabBarController.swift
//  CKLibrary
//
//  Created by mightyidler on 2020/09/05.
//

import UIKit

class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        
        let appearance = UITabBarItem.appearance()
        let attributes = [NSAttributedString.Key.font:UIFont(name: "NanumSquareRoundOTFEB", size: 10)]
        appearance.setTitleTextAttributes(attributes as [NSAttributedString.Key : Any], for: .normal)
        
    }
}

extension TabBarController: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard
            let tabViewControllers = tabBarController.viewControllers,
            let targetIndex = tabViewControllers.firstIndex(of: viewController),
            let targetView = tabViewControllers[targetIndex].view,
            let currentViewController = selectedViewController,
            let currentIndex = tabViewControllers.firstIndex(of: currentViewController)
            else { return false }

        if currentIndex != targetIndex {
            animateToView(targetView, at: targetIndex, from: currentViewController.view, at: currentIndex)
        }

        return true
    }

}

private extension TabBarController {

    func animateToView(_ toView: UIView, at toIndex: Int, from fromView: UIView, at fromIndex: Int) {
        // Position toView off screen (to the left/right of fromView)
        let screenWidth = UIScreen.main.bounds.size.width
        let offset = toIndex > fromIndex ? screenWidth : -screenWidth

        toView.frame.origin = CGPoint(
            x: toView.frame.origin.x + offset,
            y: toView.frame.origin.y
        )

        fromView.superview?.addSubview(toView)

        // Disable interaction during animation
        view.isUserInteractionEnabled = false

        UIView.animate(
            withDuration: 0.3,
            delay: 0.0,
            usingSpringWithDamping: 0.95,
            initialSpringVelocity: 0.5,
            options: .curveEaseInOut,
            animations: {
                // Slide the views by -offset
                fromView.center = CGPoint(x: fromView.center.x - offset, y: fromView.center.y)
                toView.center = CGPoint(x: toView.center.x - offset, y: toView.center.y)
            },
            completion: { _ in
                // Remove the old view from the tabbar view.
                fromView.removeFromSuperview()
                self.selectedIndex = toIndex
                self.view.isUserInteractionEnabled = true
            }
        )
    }

}
