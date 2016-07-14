//
//  UserLocationLogsViewController.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/6/16.
//  Copyright © 2016 axe. All rights reserved.
//

import UIKit

class UserLocationLogsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // Set the status bar color to the light color
        UIApplication.sharedApplication().statusBarStyle = .LightContent
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        // Set the status bar color back to default
        UIApplication.sharedApplication().statusBarStyle = .Default
    }
    
    // MARK: - Actions received here
    @IBAction func navigationBarSettingsButtonClicked(sender: UIBarButtonItem) {
        // Navigate to the Settings Page
        self.performSegueWithIdentifier("showSettingsPage", sender: self)
    }
    
    @IBAction func navigationBarAddButtonClicked(sender: UIBarButtonItem) {
        // Navigate to the add location log screen
        self.navigationController!.performSegueWithIdentifier("showNewOrUpdateLocationLog", sender: self)
    }
    
    // MARK: - Segue actions handler here
    @IBAction func unwindSegue(segue: UIStoryboardSegue) {
        if( segue.sourceViewController.isKindOfClass(NewUserLocationLogViewController) ) {
            // TODO
        }
    }

}
