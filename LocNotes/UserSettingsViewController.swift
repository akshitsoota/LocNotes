//
//  UserSettingsViewController.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/14/16.
//  Copyright © 2016 axe. All rights reserved.
//

import LocalAuthentication
import UIKit

class UserSettingsViewController: UIViewController {

    @IBOutlet weak var userNameViewHolder: UIView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var touchIDViewHolder: UIView!
    @IBOutlet weak var touchIDSwitch: UISwitch!
    @IBOutlet weak var uploadOnWifiViewHolder: UIView!
    @IBOutlet weak var uploadOnWifiSwitch: UISwitch!
    @IBOutlet weak var deleteAllLocationLogsViewHolder: UIView!
    @IBOutlet weak var logOutOfAccountViewHolder: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup views
        setupViews()
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
    
    //  MARK: - Setup views here
    func setupViews() {
        // Custom functions
        func generateTopBorder(forView: UIView!, color: UIColor?) {
            let topBorder: UIView = UIView(frame: CGRectMake(0, 0, forView.frame.size.width, 1))
            if( color == nil ) {
                topBorder.backgroundColor = UIColor.darkGrayColor()
            } else {
                topBorder.backgroundColor = color!
            }
            // Add it
            forView.addSubview(topBorder)
        }
        
        func generateBottomBorder(forView: UIView!, color: UIColor?) {
            let bottomBorder: UIView = UIView(frame: CGRectMake(0, forView.frame.size.height - 1, forView.frame.size.width, 1))
            if( color == nil ) {
                bottomBorder.backgroundColor = UIColor.darkGrayColor()
            } else {
                bottomBorder.backgroundColor = color!
            }
            // Add it
            forView.addSubview(bottomBorder)
        }
        
        // Setup top and bottom borders now
        generateTopBorder(self.userNameViewHolder, color: nil)
        generateTopBorder(self.touchIDViewHolder, color: nil)
        generateTopBorder(self.deleteAllLocationLogsViewHolder, color: nil)
        
        generateBottomBorder(self.userNameViewHolder, color: nil)
        generateBottomBorder(self.touchIDViewHolder, color: nil)
        generateBottomBorder(self.uploadOnWifiViewHolder, color: UIColor.lightGrayColor())
        generateBottomBorder(self.deleteAllLocationLogsViewHolder, color: UIColor.lightGrayColor())
        generateBottomBorder(self.logOutOfAccountViewHolder, color: nil)
        
        // Pull information from Keychain
        let userName: String! = KeychainWrapper.defaultKeychainWrapper().stringForKey("LocNotes-username")!
        let touchIDEnabled: Bool! = KeychainWrapper.defaultKeychainWrapper().boolForKey("LocNotes-TouchIDEnabled")!
        var preferredWifi: Bool? = KeychainWrapper.defaultKeychainWrapper().boolForKey("LocNotes-PrefferedUploadMediumIsWiFi")
        // Check and set defaults if necessary
        if( preferredWifi == nil ) {
            // Save one and proceed
            KeychainWrapper.defaultKeychainWrapper().setBool(true, forKey: "LocNotes-PrefferedUploadMediumIsWiFi")
            preferredWifi = true
        }
        
        // Show it on the screen
        self.userNameLabel.text = "Username: \(userName)"
        self.touchIDSwitch.on = touchIDEnabled
        self.uploadOnWifiSwitch.on = preferredWifi!
    }
    
    // MARK: - Orientation Change Listener
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()           // Let the super do its stuff
        // Re-setup the views
        setupViews()
    }
    
    // MARK: - Actions received here
    @IBAction func navigationBarBackButtonClicked(sender: AnyObject) {
        // Go back
        self.performSegueWithIdentifier("backToUserLocationLogs", sender: self)
    }
    
    @IBAction func touchIDSwitchToggled(sender: AnyObject) {
        // Check state
        if( self.touchIDSwitch.on ) {
            // Check if user has Touch ID on their phone
            if( LAContext().canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: nil) ) {
                // User has a Touch ID enabled phone
                
                // Update Keychain
                KeychainWrapper.defaultKeychainWrapper().setBool(true, forKey: "LocNotes-TouchIDEnabled")
            } else {
                // Tell the user that he/she cannot enroll for this
                CommonUtils.showDefaultAlertToUser(self, title: "Settings Issue", alertContents: "Touch ID is not either available on this device or has not been enrolled. This feature cannot be used!")
                // Switch it back off
                self.touchIDSwitch.setOn(false, animated: true)
            }
        } else {
            // Update Keychain
            KeychainWrapper.defaultKeychainWrapper().setBool(false, forKey: "LocNotes-TouchIDEnabled")
        }
    }
    
    @IBAction func wifiSwitchToggled(sender: AnyObject) {
        // Save it to Keychain
        KeychainWrapper.defaultKeychainWrapper().setBool(self.uploadOnWifiSwitch.on, forKey: "LocNotes-PrefferedUploadMediumIsWiFi")
    }
    
    @IBAction func deleteLocationLogsButtonClicked(sender: AnyObject) {
    }
    
    @IBAction func logOutAccountButtonClicked(sender: AnyObject) {
    }
}
