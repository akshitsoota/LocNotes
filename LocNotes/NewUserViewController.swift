//
//  NewUserViewController.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 6/28/16.
//  Copyright © 2016 axe. All rights reserved.
//

import UIKit

class NewUserViewController: UIViewController, UIPageViewControllerDataSource {
    
    var pageViewController: UIPageViewController!
    var pageViews: [UIViewController] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        // Else, fetch an return
        return self.pageViews[index]
    }

}