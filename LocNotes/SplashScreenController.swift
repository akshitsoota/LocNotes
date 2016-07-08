//
//  ViewController.swift
//  LocNotes
//
//  Created by axe2 on 6/22/16.
//  Copyright © 2016 axe. All rights reserved.
//

import UIKit

class SplashScreenController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup the timer to hide the splash screen and goto the next screen
        _ = NSTimer.scheduledTimerWithTimeInterval(
            2, target: self, selector: #selector(SplashScreenController.switchOutToListScreen), userInfo: nil, repeats: false
        )
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func switchOutToListScreen() {
        // Check keychain values and then decide which screen has to be shown
        let isUserLoggedIn: Bool? = KeychainWrapper.defaultKeychainWrapper().boolForKey("LocNotes-userLoggedIn")
        
        if( isUserLoggedIn == nil || !isUserLoggedIn! ) {
            // No value in KeyChain or the user is NOT logged in
            performSegueWithIdentifier("showNewUser", sender: self)
        } else if( isUserLoggedIn! ) {
            // There is a value in KeyChain and the user is logged in
            performSegueWithIdentifier("showLoggedInUser", sender: self) //"showNewUser", sender: self) //showLoggedInUser", sender: self)
        }
    }
    
}

