//
//  MonitorPageViewController.swift
//  HeartRate
//
//  Created by Lyolia on 25.02.2021.
//  Copyright © 2021 Lyolia. All rights reserved.
//

import UIKit

protocol MonitorPageViewControllerDelegate: class {
    func scrollToNextView(change: Int)
    func scrollToPrevious()
    func resetPage()
}

class MonitorPageViewController: UIPageViewController {

    private(set) lazy var orderedViewControllers: [UIViewController] = {
        
        let firstViewController = UIStoryboard(name: "MonitorStartViewController", bundle: nil).instantiateViewController(withIdentifier: "MonitorStartViewController") as! MonitorStartViewController
        firstViewController.monitorPageViewControllerDelegate = self
        
        let lastViewController = UIStoryboard(name: "MonitorFinishViewController", bundle: nil).instantiateViewController(withIdentifier: "MonitorFinishViewController") as! MonitorFinishViewController
        lastViewController.monitorPageViewControllerDelegate = self
        
        return [firstViewController, lastViewController]
    }()
    
    public var currentPage: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
        
        if let initialViewController = orderedViewControllers.first {
            scrollToViewController(viewController: initialViewController)
        }
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//            if let nextViewController = segue.destination as? MonitorFinishViewController {
//                nextViewController.pulseView.text = "5"
//            }
//    }
    
    func scrollToNextViewController() {
        if let visibleViewController = viewControllers?.first,
            let nextViewController = pageViewController(self, viewControllerAfter: visibleViewController) {
            if let _nextViewController  = nextViewController as? MonitorFinishViewController {
                _nextViewController.rateNum = currentPage
                scrollToViewController(viewController: _nextViewController)
            } else {
                scrollToViewController(viewController: nextViewController)
            }
                
        }
    }
    
    func scrollToPreviosViewController() {
        if let visibleController = viewControllers?.first,
           let previousController = pageViewController(self, viewControllerBefore: visibleController) {
            scrollToViewController(viewController: previousController, direction: .reverse)
        }
    }
    
    func scrollToViewController(index newIndex: Int) {
        if let firstViewController = viewControllers?.first,
            let currentIndex = orderedViewControllers.firstIndex(of: firstViewController) {
            let direction: UIPageViewController.NavigationDirection = newIndex >= currentIndex ? .forward : .reverse
                let nextViewController = orderedViewControllers[newIndex]
                scrollToViewController(viewController: nextViewController, direction: direction)
        }
    }

    private func scrollToViewController(viewController: UIViewController,
                                        direction: UIPageViewController.NavigationDirection = .forward) {
        setViewControllers([viewController],
            direction: direction,
            animated: true,
            completion: { (finished) -> Void in
                self.notifyTutorialDelegateOfNewIndex()
        })
    }
    
    private func notifyTutorialDelegateOfNewIndex() {
        if let firstViewController = viewControllers?.first,
            let index = orderedViewControllers.firstIndex(of: firstViewController) {
        }
    }
    
}

extension MonitorPageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController) else {
                return nil
            }
            
            let previousIndex = viewControllerIndex - 1
            
            guard previousIndex > 0 else {
                return nil
            }
            
            guard orderedViewControllers.count > previousIndex else {
                return nil
            }
            
            return orderedViewControllers[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController) else {
                return nil
            }
            
            let nextIndex = viewControllerIndex + 1

            guard orderedViewControllers.count > nextIndex else {
                return nil
            }
            
            return orderedViewControllers[nextIndex]
    }
    
}

extension MonitorPageViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool) {
        notifyTutorialDelegateOfNewIndex()
    }
    
}

extension MonitorPageViewController: MonitorPageViewControllerDelegate {
    func resetPage() {
        currentPage = 0
    }
    
    func scrollToNextView(change : Int) {
        self.currentPage = change
        self.scrollToNextViewController()
    }
    
    func scrollToPrevious(){
       // self.scrollToPreviosViewController()
        self.currentPage = 0 // viewControllerIndex
        self.scrollToViewController(index: 0)
    }
    
    
}


