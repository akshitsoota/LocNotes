//
//  NewUserViewController.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 6/28/16.
//  Copyright © 2016 axe. All rights reserved.
//

// Useful UIPageViewController Tutorial used:
//   https://www.youtube.com/watch?v=8bltsDG2ENQ

import UIKit

class NewUserViewController: UIViewController, UIPageViewControllerDataSource {
    
    var pageViewController: UIPageViewController!
    var pageViews: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialze the pageView array with the identifiers for the PageViewController pages
        pageViews.append("NewUserPageView1")
        // Also initialize the PageViewController
        self.pageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("NewUserPageView") as! UIPageViewController
        self.pageViewController.dataSource = self   // This very class will be the UIPageViewControllerDataSource for the pages
        // Setup the starting Page to be shown on the UIPageViewController
        let startingPage = self.getViewControllerAtIndex(0) as! NewUserPageContentViewController
        var viewControllers: [UIViewController] = []
        viewControllers.append(startingPage)
        
        self.pageViewController.setViewControllers(viewControllers, direction: .Forward, animated: true, completion: nil)
        // Now add this to our screen
        self.pageViewController.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        self.addChildViewController(pageViewController)
        self.view.addSubview(pageViewController.view)
        self.pageViewController.didMoveToParentViewController(self)     // We will be handling all those function calls
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Function to fetch View Controller at a given index
    private func getViewControllerAtIndex(index: Int) -> UIViewController {
        // Check if the index is out of bounds
        if( index >= self.pageViews.count ) {
            return UIViewController() // Out Of Bounds, so return a new UIViewController
        }
        // Else, instantiate and return
        let viewController = self.storyboard?.instantiateViewControllerWithIdentifier(self.pageViews[index]) as! NewUserPageContentViewController
        viewController.pageIndex = index
        // Return
        return viewController
    }
    
    // MARK: - Page View Controller Data Source
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        // Presents the page before the current one
        let viewController = viewController as! NewUserPageContentViewController
        let pageIndex = viewController.pageIndex as Int
        
        // Check if left out of bounds
        if( pageIndex == 0 || pageIndex == NSNotFound ) {
            return nil          // We've nothing to show
        }
        // Else, resolve and send back
        return getViewControllerAtIndex(pageIndex - 1)
        
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        // Presents the page after the current one
        let viewController = viewController as! NewUserPageContentViewController
        let pageIndex = viewController.pageIndex as Int
        
        // Check if not found or right out of bounds
        if( pageIndex == self.pageViews.count - 1 || pageIndex == NSNotFound ) {
            return nil          // We've nothing to show
        }
        // Else, resolve and send back
        return getViewControllerAtIndex(pageIndex + 1)
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        // Returns the total count of the number of pages
        return self.pageViews.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        // Returns the initial page index
        return 0
    }

}