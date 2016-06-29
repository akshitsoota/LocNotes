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

class NewUserViewController: UIViewController, UIPageViewControllerDataSource, UIScrollViewDelegate {
    
    @IBOutlet weak var buttonsStackView: UIStackView!
    
    var pageViewController: UIPageViewController!
    var pageViews: [String] = []
    var pageViewBackgrounds: [UIColor] = []
    
    var prevContentOffsetX: CGFloat!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialze the pageView array with the identifiers for the PageViewController pages
        pageViews.append("NewUserPageView1")
        pageViews.append("NewUserPageView1")
        
        pageViewBackgrounds.append(UIColor(red: 246/255, green: 169/255, blue: 26/255, alpha: 1))
        pageViewBackgrounds.append(UIColor(red: 26/255, green: 169/255, blue: 246/255, alpha: 1))
        
        // Also initialize the PageViewController
        self.pageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("NewUserPageView") as! UIPageViewController
        self.pageViewController.dataSource = self   // This very class will be the UIPageViewControllerDataSource for the pages
        
        // Setup the starting Page to be shown on the UIPageViewController
        let startingPage = self.getViewControllerAtIndex(0) as! NewUserPageContentViewController
        var viewControllers: [UIViewController] = []
        viewControllers.append(startingPage)
        
        self.pageViewController.setViewControllers(viewControllers, direction: .Forward, animated: true, completion: nil)
        
        //
        for view in self.pageViewController.view.subviews {
            if let scrollView = view as? UIScrollView {
                scrollView.delegate = self
            }
        }
        
        // Now add this to our screen
        self.pageViewController.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height - self.buttonsStackView.frame.height - 20)
        self.addChildViewController(pageViewController)
        self.view.addSubview(pageViewController.view)
        self.pageViewController.didMoveToParentViewController(self)     // We will be handling all those function calls
        
        // Set a background for the first page
        self.view.backgroundColor = pageViewBackgrounds[0]
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
    
    // MARK: - UIScrollViewDelegate Methods
    func scrollViewDidScroll(scrollView: UIScrollView) {
        NSLog("scrollViewDidScrollCalled \(self.view.frame.width)")
        //
        let oldColor = self.pageViewBackgrounds[0]
        let newColor = self.pageViewBackgrounds[1]
        //
        var oR: CGFloat = 0, oG: CGFloat = 0, oB: CGFloat = 0, oA: CGFloat = 0
        var nR: CGFloat = 0, nG: CGFloat = 0, nB: CGFloat = 0, nA: CGFloat = 0
        oldColor.getRed(&oR, green: &oG, blue: &oB, alpha: &oA)
        newColor.getRed(&nR, green: &nG, blue: &nB, alpha: &nA)
        // Resolve percentage of scroll
        let pscroll = ((scrollView.contentOffset.x - self.view.frame.width) / self.view.frame.width)
        // Solve new color
        let pR = (nR - oR) * pscroll
        let pG = (nG - oG) * pscroll
        let pB = (nB - oB) * pscroll
        // Color
        self.view.backgroundColor = UIColor(red: pR + oR, green: pG + oG, blue: pB + oB, alpha: 1)
        // Save and check with prev
        if( scrollView.contentOffset.x == self.view.frame.width && self.prevContentOffsetX > scrollView.contentOffset.x ) {
            // User has hit the new screen
            self.view.backgroundColor = self.pageViewBackgrounds[1]
        } else {
            prevContentOffsetX = scrollView.contentOffset.x
        }
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        NSLog("scrollViewWillBeginDragging \(scrollView.contentOffset)")
        //
        let oldColor = self.pageViewBackgrounds[0]
        let newColor = self.pageViewBackgrounds[1]
        //
        var oR: CGFloat = 0, oG: CGFloat = 0, oB: CGFloat = 0, oA: CGFloat = 0
        var nR: CGFloat = 0, nG: CGFloat = 0, nB: CGFloat = 0, nA: CGFloat = 0
        oldColor.getRed(&oR, green: &oG, blue: &oB, alpha: &oA)
        newColor.getRed(&nR, green: &nG, blue: &nB, alpha: &nA)
        // Resolve percentage of scroll
        let pscroll = ((scrollView.contentOffset.x - self.view.frame.width) / self.view.frame.width)
        // Solve new color
        let pR = (nR - oR) * pscroll
        let pG = (nG - oG) * pscroll
        let pB = (nB - oB) * pscroll
        // Color
        self.view.backgroundColor = UIColor(red: pR + oR, green: pG + oG, blue: pB + oB, alpha: 1)
        // Save and check with prev
        if( scrollView.contentOffset.x == self.view.frame.width && self.prevContentOffsetX > scrollView.contentOffset.x ) {
            // User has hit the new screen
            self.view.backgroundColor = self.pageViewBackgrounds[1]
        } else {
            prevContentOffsetX = scrollView.contentOffset.x
        }
    }

}