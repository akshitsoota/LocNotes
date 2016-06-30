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

class NewUserViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var buttonsStackView: UIStackView!
    
    // Main PageViewController that is shown on the screen
    var pageViewController: UIPageViewController!
    // List of name identifiers to all the pages that will be shown on the screen
    var pageViews: [String] = []
    // List of the backgrounds corresponding to each of the pageViews
    var pageViewBackgrounds: [UIColor] = []
    // Keeps track of the last contentOffset value for the PageViewController on the screen
    var lastContentOffset: CGFloat!
    // Keeps the scroll that the user is executing
    var directionOfScroll: Int! = -1 // -1 = Unknown; 0 = Left; 1 = Right
    // Holds the current PageView Index
    var currentPageViewIndex: Int! = 0

    override func viewDidLoad() {
        super.viewDidLoad() // Let the super do its stuff
        
        // Initialze the pageView array with the identifiers for the PageViewController pages
        pageViews.append("NewUserPageView1")
        pageViews.append("NewUserPageView1")
        
        // Initialize pageViewBackgrounds with as many elements as pageViews
        for _ in 0..<self.pageViews.count {
            pageViewBackgrounds.append(UIColor.clearColor())
        }
        
        // Also initialize the PageViewController
        self.pageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("NewUserPageView") as! UIPageViewController
        self.pageViewController.dataSource = self   // This very class will be the UIPageViewControllerDataSource for the pages
        self.pageViewController.delegate = self     // Let us deal with all the events
        
        // Setup the starting Page to be shown on the UIPageViewController
        let startingPage = self.getViewControllerAtIndex(0) as! NewUserPageContentViewController
        var viewControllers: [UIViewController] = []
        viewControllers.append(startingPage)
        
        self.pageViewController.setViewControllers(viewControllers, direction: .Forward, animated: true, completion: nil)
        
        // Now add this to our screen
        self.pageViewController.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height - self.buttonsStackView.frame.height - 20)
        self.addChildViewController(pageViewController)
        self.view.addSubview(pageViewController.view)
        self.pageViewController.didMoveToParentViewController(self)     // We will be handling all those function calls
        
        // Have all the PageViewController ScrollView delegates be dealt by this class
        for view in self.pageViewController.view.subviews {
            if let scrollView = view as? UIScrollView {
                scrollView.delegate = self
            }
        }
        
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
        // Also let us store the background color of the View and return one with the transparent color because we deal with the background color in the UIScrollViewDelegate
        if( self.pageViewBackgrounds.count == self.pageViews.count ) {
            // We can safely replace the background image color
            self.pageViewBackgrounds[index] = viewController.view.backgroundColor!
        }
        // Scrap the background color from the view that we are returning right now
        viewController.view.backgroundColor = UIColor.clearColor()
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
    
    // MARK: - Page View Controller Delegate
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        // Help resolve the current page index
        if( !completed ) {
            return
        }
        
        // Only save the new page index once the page animation has completed
        let pageContentViewController = pageViewController.viewControllers![0] as! NewUserPageContentViewController
        self.currentPageViewIndex = pageContentViewController.pageIndex
        
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        // Returns the total count of the number of pages
        return self.pageViews.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        // Returns the initial page index
        return 0
    }
    
    // MARK: - ScrollViewDelegate Functions
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        // The user just started dragging. Let us save the initial contentOffset in the X-direction
        self.lastContentOffset = scrollView.contentOffset.x
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        // The user is dragging the ScrollView. Let us compare and check the direction
        if( self.lastContentOffset < scrollView.contentOffset.x ) {
            self.directionOfScroll = 1       // Moved right
        } else if( self.lastContentOffset > scrollView.contentOffset.x ) {
            self.directionOfScroll = 0       // Moved left
        } else {
            self.directionOfScroll = -1 // Unknown
            return                      // We don't want to change the background as there was no movement
        }
        
        // See if we've enough backgrounds to scroll through
        if( self.pageViews.count != self.pageViewBackgrounds.count ) {
            return                      // We don't have enough background as pages to scroll through
        }
        
        // Check the direction of scroll now
        let currentPageBackgroundColor = self.pageViewBackgrounds[self.currentPageViewIndex]
        var nextPageBackgroundColor: UIColor! = nil
        
        if( self.directionOfScroll == 1 ) {
            nextPageBackgroundColor = self.pageViewBackgrounds[self.currentPageViewIndex + 1]
        } else if( self.directionOfScroll == 0 ) {
            nextPageBackgroundColor = self.pageViewBackgrounds[self.currentPageViewIndex - 1]
        }
        
        // Extract the old and new RGBA values
        var origRed: CGFloat = 0, origBlue: CGFloat = 0, origGreen: CGFloat = 0, origAlpha: CGFloat = 0
        var finalRed: CGFloat = 0, finalBlue: CGFloat = 0, finalGreen: CGFloat = 0, finalAlpha: CGFloat = 0
        
        currentPageBackgroundColor.getRed(&origRed, green: &origGreen, blue: &origBlue, alpha: &origAlpha)
        nextPageBackgroundColor.getRed(&finalRed, green: &finalGreen, blue: &finalBlue, alpha: &finalAlpha)
        
        // Calculate the percentage of the scroll
        let percentageOfScroll = abs( ( scrollView.contentOffset.x - scrollView.frame.width ) / scrollView.frame.width )
        
        // Resolve the new UIColor to be set
        let perctRed: CGFloat = ((finalRed - origRed) * percentageOfScroll)
        let perctGreen: CGFloat = ((finalGreen - origGreen) * percentageOfScroll)
        let perctBlue: CGFloat = ((finalBlue - origBlue) * percentageOfScroll)
        let perctAlpha: CGFloat = ((finalAlpha - origAlpha) * percentageOfScroll)
        
        let newBackgroundColor: UIColor = UIColor(red: origRed + perctRed, green: origGreen + perctGreen, blue: origBlue + perctBlue, alpha: origAlpha + perctAlpha)
        
        // Now set the new background color
        self.view.backgroundColor = newBackgroundColor
    }

}