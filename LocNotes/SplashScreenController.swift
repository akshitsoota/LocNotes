//
//  ViewController.swift
//  LocNotes
//
//  Created by axe2 on 6/22/16.
//  Copyright © 2016 axe. All rights reserved.
//

import LocalAuthentication
import UIKit

class SplashScreenController: UIViewController {
    
    @IBOutlet weak var fingerPrintImage: UIImageView!
    @IBOutlet weak var passwordImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup the timer to hide the splash screen and goto the next screen
        _ = NSTimer.scheduledTimerWithTimeInterval(
            2, target: self, selector: #selector(SplashScreenController.switchOutToListScreen), userInfo: nil, repeats: false
        )
        // Hide the fingerprint image by default
        self.fingerPrintImage.hidden = true
        self.passwordImage.hidden = true
        // Setup tap listener on it the images
        let tapListener: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SplashScreenController.promptTouchID))
        self.fingerPrintImage.addGestureRecognizer(tapListener)
        
        let tapListenerPassword: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SplashScreenController.promptBackupPassword))
        self.passwordImage.addGestureRecognizer(tapListenerPassword)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func switchOutToListScreen() {
        // Check for Touch ID Enabled or not
        var touchIDEnabled: Bool? = KeychainWrapper.defaultKeychainWrapper().boolForKey("LocNotes-TouchIDEnabled")
        if( touchIDEnabled == nil ) {
            // Set it and save as false (default)
            KeychainWrapper.defaultKeychainWrapper().setBool(false, forKey: "LocNotes-TouchIDEnabled")
            // Make changes here
            touchIDEnabled = false
        }
        
        // Check keychain values and then decide which screen has to be shown
        let isUserLoggedIn: Bool? = KeychainWrapper.defaultKeychainWrapper().boolForKey("LocNotes-userLoggedIn")
        
        if( isUserLoggedIn == nil || !isUserLoggedIn! ) {
            // No value in KeyChain or the user is NOT logged in
            performSegueWithIdentifier("showNewUser", sender: self)
        } else if( isUserLoggedIn! ) {
            // There is a value in KeyChain and the user is logged in; Split based on if Touch ID is enabled
            if( !(touchIDEnabled!) ) {
                // Show the user their Location Logs
                self.performSegueWithIdentifier("showLoggedInUser", sender: self) //"showNewUser", sender: self) //showLoggedInUser", sender: self)
            } else {
                promptTouchID()
            }
        }
    }
    
    // MARK: - Touch ID Function(s)
    func promptTouchID() {
        // Prompt user for Touch ID
        LAContext().evaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: "Use Touch ID to gain access to your Location Logs",
                                   reply: {(success: Bool, error: NSError?) -> Void in
                                    
            // Process Touch ID response here
            if( success ) {
                // Run this on the main thread
                dispatch_async(dispatch_get_main_queue(), {
                    self.performSegueWithIdentifier("showLoggedInUser", sender: self)       // Goto the Location Logs screen
                })
            } else {
                // Process the error here
                switch( error!.code ) {
                case LAError.AuthenticationFailed.rawValue, LAError.UserCancel.rawValue, LAError.UserFallback.rawValue, LAError.SystemCancel.rawValue, LAError.TouchIDLockout.rawValue:
                    // Show the finger on the screen
                    dispatch_async(dispatch_get_main_queue(), {
                        self.fingerPrintImage.hidden = false
                        self.passwordImage.hidden = false
                    })
                    break;
                case LAError.PasscodeNotSet.rawValue, LAError.TouchIDNotAvailable.rawValue, LAError.TouchIDNotEnrolled.rawValue:
                    // Tell the user
                    dispatch_async(dispatch_get_main_queue(), {
                        self.fingerPrintImage.hidden = false
                        self.passwordImage.hidden = false
                        
                        CommonUtils.showDefaultAlertToUser(self, title: "Touch ID issues", alertContents: "Please enable Touch ID to access your Location Logs.")
                    })
                    break;
                default:
                    // We shouldn't reach here
                    return
                }
            }
                                    
        })
    }
    
    func promptBackupPassword() {
        
        // Present Password Alert
        // CITATION: http://stackoverflow.com/a/25713688/705471
        
        var inputTextField: UITextField?
        let passwordPrompt = UIAlertController(title: "Enter Password", message: "You had chosen a backup password to unlock LocNotes as an alternative to Touch ID. Please enter that pasword now to unlock LocNotes.", preferredStyle: UIAlertControllerStyle.Alert)
        passwordPrompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        passwordPrompt.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
            // Now do whatever you want with inputTextField (remember to unwrap the optional)
            if( CommonUtils.generateSHA512((inputTextField!.text?.dataUsingEncoding(NSUTF8StringEncoding))!) ==
                KeychainWrapper.defaultKeychainWrapper().stringForKey("LocNotes-TouchIDBackupPwd")! )
            {
                
                // Run this on the main thread
                dispatch_async(dispatch_get_main_queue(), {
                    self.performSegueWithIdentifier("showLoggedInUser", sender: self)       // Goto the Location Logs screen
                })
                
            } else {
                // Show failure message to the user
                dispatch_async(dispatch_get_main_queue(), {
                    // Tell the user that it couldn't be disabled because the password didn't match
                    CommonUtils.showDefaultAlertToUser(self, title: "Wrong Credentials", alertContents: "The backup password entered doesn't match the one you had used while enrolling for Touch ID. Please try again!")
                })
            }
        }))
        passwordPrompt.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "Password"
            textField.secureTextEntry = true
            inputTextField = textField
        })
        // Show the Password Box
        self.presentViewController(passwordPrompt, animated: true, completion: nil)
        
    }
    
}

