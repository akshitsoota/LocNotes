//
//  UserSettingsViewController.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/14/16.
//  Copyright © 2016 axe. All rights reserved.
//

import LocalAuthentication
import CoreData
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
    // Holds the loading screen that shows the user progress of their action
    var loadingScreen: UIView!
    
    // Core Data Managed Context
    var managedContext : NSManagedObjectContext?
    
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
        generateBottomBorder(self.touchIDViewHolder, color: UIColor.lightGrayColor())
        generateBottomBorder(self.uploadOnWifiViewHolder, color: nil)
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
        // Don't fill this one in because we haven't worked on this feature yet: 
        //   self.uploadOnWifiSwitch.on = preferredWifi!
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
                
                // Present Password Alert
                // CITATION: http://stackoverflow.com/a/25713688/705471
                
                var inputTextField: UITextField?
                let passwordPrompt = UIAlertController(title: "Enter Password", message: "Choose a backup password in case Touch ID fails to help you unlock LocNotes.", preferredStyle: UIAlertControllerStyle.Alert)
                passwordPrompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
                    dispatch_async(dispatch_get_main_queue(), {
                        self.touchIDSwitch.setOn(false, animated: true)
                    })
                }))
                passwordPrompt.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
                    // Now do whatever you want with inputTextField (remember to unwrap the optional)
                    if( inputTextField!.text?.isEmpty == false )
                    {
                        // If the password matched, then update keychain
                        KeychainWrapper.defaultKeychainWrapper().setBool(true, forKey: "LocNotes-TouchIDEnabled")
                        // And save the password
                        KeychainWrapper.defaultKeychainWrapper().setString(CommonUtils.generateSHA512((inputTextField!.text?.dataUsingEncoding(NSUTF8StringEncoding))!), forKey: "LocNotes-TouchIDBackupPwd")
                    } else {
                        // Show failure message to the user
                        dispatch_async(dispatch_get_main_queue(), {
                            // Tell the user that we couldn't enable it as they entered an empty password
                            CommonUtils.showDefaultAlertToUser(self, title: "Invalid Credentials", alertContents: "Unable to enable Touch ID as the backup password you entered was empty. Please enter a valid password and try again!")
                            // Switch it back off
                            self.touchIDSwitch.setOn(false, animated: true)
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
                
            } else {
                // Tell the user that he/she cannot enroll for this
                CommonUtils.showDefaultAlertToUser(self, title: "Settings Issue", alertContents: "Touch ID is not either unavailable on this device or has not been enrolled. This feature cannot be used!")
                // Switch it back off
                self.touchIDSwitch.setOn(false, animated: true)
            }
        } else {
            // Present Password Alert
            // CITATION: http://stackoverflow.com/a/25713688/705471
            
            var inputTextField: UITextField?
            let passwordPrompt = UIAlertController(title: "Enter Password", message: "You had chosen a backup password to unlock LocNotes if Touch ID failed. Please enter that pasword now to disable Touch ID integration.", preferredStyle: UIAlertControllerStyle.Alert)
            passwordPrompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
                dispatch_async(dispatch_get_main_queue(), {
                    self.touchIDSwitch.setOn(true, animated: true)
                })
            }))
            passwordPrompt.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
                // Now do whatever you want with inputTextField (remember to unwrap the optional)
                if( CommonUtils.generateSHA512((inputTextField!.text?.dataUsingEncoding(NSUTF8StringEncoding))!) ==
                    KeychainWrapper.defaultKeychainWrapper().stringForKey("LocNotes-TouchIDBackupPwd")! )
                {
                    // If the password matched, then update keychain
                    KeychainWrapper.defaultKeychainWrapper().setBool(false, forKey: "LocNotes-TouchIDEnabled")
                    // And remove the password
                    KeychainWrapper.defaultKeychainWrapper().setString("", forKey: "LocNotes-TouchIDBackupPwd")
                } else {
                    // Show failure message to the user
                    dispatch_async(dispatch_get_main_queue(), {
                        // Tell the user that it couldn't be disabled because the password didn't match
                        CommonUtils.showDefaultAlertToUser(self, title: "Wrong Credentials", alertContents: "The backup password entered doesn't match the one you had used while enrolling for Touch ID. Please try again!")
                        // Switch it back off
                        self.touchIDSwitch.setOn(true, animated: true)
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
    
    @IBAction func wifiSwitchToggled(sender: AnyObject) {
        // Save it to Keychain
        KeychainWrapper.defaultKeychainWrapper().setBool(self.uploadOnWifiSwitch.on, forKey: "LocNotes-PrefferedUploadMediumIsWiFi")
    }
    
    @IBAction func deleteLocationLogsButtonClicked(sender: AnyObject) {
        // Ask the user for confirmation
        let actionSheet: UIAlertController = UIAlertController(title: nil, message: "Are you sure you want to delete all your location logs? This action cannot be undone!", preferredStyle: .ActionSheet)
        let deleteAction: UIAlertAction = UIAlertAction(title: "Delete", style: .Destructive, handler: {(alert: UIAlertAction) -> Void in
            // Show up a loading screen
            self.loadingScreen = CommonUtils.returnLoadingScreenView(self, size: UIScreen.mainScreen().bounds)
            CommonUtils.setLoadingTextOnLoadingScreenView(self.loadingScreen, newLabelContents: "Deleting your location logs...")
            self.navigationController?.view.addSubview(self.loadingScreen)
            
            // Check the Login Token Validity
            let tokenRenewalState: NSDictionary? = UserAuthentication.renewLoginToken()
            // Check if nil
            if( tokenRenewalState == nil ) {
                // We failed to renew the login token, tell the user on the main thread
                dispatch_async(dispatch_get_main_queue(), {
                    // Hide the loading screen
                    self.loadingScreen.removeFromSuperview()
                    // Tell the user where we hit a snag
                    CommonUtils.showDefaultAlertToUser(self, title: "Hit a Snag!", alertContents: "We are having issues with our internal framework. Please try again later!")
                })
                // Exit
                return
            }
            // Else, process
            if(   tokenRenewalState!["status"] as! String == "invalid_non_json_response" ||
                ( tokenRenewalState!["status"] as! String == "no_renewal" &&
                    tokenRenewalState!["reason"] as! String == "backend_failure" ) ||
                ( tokenRenewalState!["status"] as! String == "not_possible_request_error" ) ) {
                
                // We failed to renew the login token, tell the user on the main thread
                dispatch_async(dispatch_get_main_queue(), {
                    // Hide the loading screen
                    self.loadingScreen.removeFromSuperview()
                    // Tell the user where we hit a snag
                    CommonUtils.showDefaultAlertToUser(self, title: "Hit a Snag!", alertContents: "The server returned an invalid response while attempting to verify your login credentials. Please try again later!")
                })
                // Exit
                return
                
            } else if( tokenRenewalState!["status"] as! String == "renewed_but_failed" && tokenRenewalState!["reason"] as! String == "keychain_failed" ) {
                
                // We failed to renew the login token, tell the user on the main thread
                dispatch_async(dispatch_get_main_queue(), {
                    // Hide the loading screen
                    self.loadingScreen.removeFromSuperview()
                    // Tell the user where we hit a snag
                    CommonUtils.showDefaultAlertToUser(self, title: "Hit a Snag!", alertContents: "We failed to save your fresh login token into Keychain. Please try again later!")
                })
                // Exit
                return
                
            } else if( tokenRenewalState!["status"] as! String == "no_renewal" && tokenRenewalState!["reason"] as! String == "invalid_cred" ) {
                
                // We failed to renew the login token, tell the user on the main thread
                dispatch_async(dispatch_get_main_queue(), {
                    // Hide the loading screen
                    self.loadingScreen.removeFromSuperview()
                    // Tell the user where we hit a snag
                    CommonUtils.showDefaultAlertToUser(self, title: "Hit a Snag!", alertContents: "Your login credentials have expired. Please try logout and log back in to delete all your Location Logs.")
                })
                // Exit
                return
                
            } else if( ( tokenRenewalState!["status"] as! String == "no_renewal" && tokenRenewalState!["reason"] as! String == "not_needed" ) ||
                       ( tokenRenewalState!["status"] as! String == "renewed" && tokenRenewalState!["reason"] == nil ) ) {
                
                // Perfect, just proceed with the rest of the job
                
            }
            
            // Send the request to log the user out
            let awsEndpoint: String = CommonUtils.fetchFromPropertiesList("endpoints", fileExtension: "plist", key: "awsEC2EndpointURL")!
            let deleteAllLocationLogsURL: String = CommonUtils.fetchFromPropertiesList("endpoints", fileExtension: "plist", key: "deleteAllLocationLogsURL")!
            
            let userName: String! = KeychainWrapper.defaultKeychainWrapper().stringForKey("LocNotes-username")!
            let userLoginToken: String! = KeychainWrapper.defaultKeychainWrapper().stringForKey("LocNotes-loginToken")!
            
            // Now start the async request
            let asyncRequestURL: NSURL! = NSURL(string: "http://" + awsEndpoint + deleteAllLocationLogsURL)
            let asyncSession: NSURLSession! = NSURLSession.sharedSession()
            
            let asyncRequest: NSMutableURLRequest! = NSMutableURLRequest(URL: asyncRequestURL)
            asyncRequest.HTTPMethod = "POST"
            asyncRequest.cachePolicy = .ReloadIgnoringLocalCacheData
            asyncRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            asyncRequest.setValue(UserAuthentication.generateAuthorizationHeader(userName, userLoginToken: userLoginToken), forHTTPHeaderField: "Authorization")
            
            let asyncTask = asyncSession.dataTaskWithRequest(asyncRequest, completionHandler: {(data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                // Check for any errors
                if( error != nil ) {
                    // Tell the user that we failed to log them out
                    dispatch_async(dispatch_get_main_queue(), {
                        // Hide the loading screen
                        self.loadingScreen.removeFromSuperview()
                        // Alert the user
                        CommonUtils.showDefaultAlertToUser(self, title: "Server Error", alertContents: "We received an invalid response from the server. Please try again later!")
                    })
                    // Return
                    return
                }
                
                // Check the response
                do {
                    
                    let jsonResponse: [String: AnyObject] = try (NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions()) as? [String: AnyObject])!
                    // Now process the response
                    let status = jsonResponse["status"]
                    
                    if( status == nil ) {
                        // We've got an error
                        dispatch_async(dispatch_get_main_queue(), {
                            // Hide the loading screen
                            self.loadingScreen.removeFromSuperview()
                            // Alert the user
                            CommonUtils.showDefaultAlertToUser(self, title: "Server Error", alertContents: "We received an invalid response from the server. Please try again later!")
                        })
                        // Return
                        return
                    }
                    
                    let strStatus: String! = status as! String
                    
                    if( strStatus == "success" ) {
                        
                        // Clear up CoreData
                        self.clearUpCoreData()
                        
                        // Take the user to the login screen
                        dispatch_async(dispatch_get_main_queue(), {
                            self.loadingScreen.removeFromSuperview()
                            self.performSegueWithIdentifier("backToUserLocationLogs", sender: self)
                        })
                        // And we're done
                        return
                        
                    }
                    
                } catch {
                    // Tell the user that we couldn't log them out
                    dispatch_async(dispatch_get_main_queue(), {
                        // Hide the loading screen
                        self.loadingScreen.removeFromSuperview()
                        // Alert the user
                        CommonUtils.showDefaultAlertToUser(self, title: "Server Error", alertContents: "We received an invalid response from the server. Please try again later!")
                    })
                    // Return
                    return
                }
            })
            asyncTask.resume() // Start the task now
            // Return
            return
        })
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
        // Add the options to the Action Sheet
        actionSheet.addAction(deleteAction)
        actionSheet.addAction(cancelAction)
        // Now present the Action Sheet
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func logOutAccountButtonClicked(sender: AnyObject) {
        // Ask the user for confirmation
        let actionSheet: UIAlertController = UIAlertController(title: nil, message: "Are you sure you want to log out of your account? You will not loose any location logs by doing so.", preferredStyle: .ActionSheet)
        let deleteAction: UIAlertAction = UIAlertAction(title: "Log Out", style: .Destructive, handler: {(alert: UIAlertAction) -> Void in
            // Show up a loading screen
            self.loadingScreen = CommonUtils.returnLoadingScreenView(self, size: UIScreen.mainScreen().bounds)
            CommonUtils.setLoadingTextOnLoadingScreenView(self.loadingScreen, newLabelContents: "Logging you out...")
            self.navigationController?.view.addSubview(self.loadingScreen)
            
            // Send the request to log the user out
            let awsEndpoint: String = CommonUtils.fetchFromPropertiesList("endpoints", fileExtension: "plist", key: "awsEC2EndpointURL")!
            let invalidateTokenURL: String = CommonUtils.fetchFromPropertiesList("endpoints", fileExtension: "plist", key: "invalidateLoginTokenURL")!
            
            let userName: String! = KeychainWrapper.defaultKeychainWrapper().stringForKey("LocNotes-username")!
            let userLoginToken: String! = KeychainWrapper.defaultKeychainWrapper().stringForKey("LocNotes-loginToken")!
            let userTokenExpiry: Double! = KeychainWrapper.defaultKeychainWrapper().doubleForKey("LocNotes-tokenExpiry")!
            
            // Now start the async request
            let asyncRequestURL: NSURL! = NSURL(string: "http://" + awsEndpoint + invalidateTokenURL)
            let asyncSession: NSURLSession! = NSURLSession.sharedSession()
            
            let asyncRequest: NSMutableURLRequest! = NSMutableURLRequest(URL: asyncRequestURL)
            asyncRequest.HTTPMethod = "POST"
            asyncRequest.cachePolicy = .ReloadIgnoringLocalCacheData
            asyncRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
            // Let us form a dictionary of <K, V> pairs to be sent
            // REFERENCE: http://stackoverflow.com/a/28009796/705471
            let requestParams: Dictionary<String, String>! = ["username": userName,
                                                              "logintoken": userLoginToken,
                                                              "logintokenexpiry": String(userTokenExpiry)]
            var firstParamAdded: Bool! = false
            let paramKeys: Array<String>! = Array(requestParams.keys)
            var requestBody = ""
            for key in paramKeys {
                if( !firstParamAdded ) {
                    requestBody += key + "=" + requestParams[key]!
                    firstParamAdded = true
                } else {
                    requestBody += "&" + key + "=" + requestParams[key]!
                }
            }
            
            requestBody = requestBody.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
            asyncRequest.HTTPBody = requestBody.dataUsingEncoding(NSUTF8StringEncoding)
            
            let asyncTask = asyncSession.dataTaskWithRequest(asyncRequest, completionHandler: {(data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                // Check for any errors
                if( error != nil ) {
                    // Tell the user that we failed to log them out
                    dispatch_async(dispatch_get_main_queue(), {
                        // Hide the loading screen
                        self.loadingScreen.removeFromSuperview()
                        // Alert the user
                        CommonUtils.showDefaultAlertToUser(self, title: "Server Error", alertContents: "We received an invalid response from the server. Please try again later!")
                    })
                    // Return
                    return
                }
                
                // Check the response
                do {
                    
                    let jsonResponse: [String: AnyObject] = try (NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions()) as? [String: AnyObject])!
                    // Now process the response
                    let status = jsonResponse["status"]
                    
                    if( status == nil ) {
                        // We've got an error
                        dispatch_async(dispatch_get_main_queue(), {
                            // Hide the loading screen
                            self.loadingScreen.removeFromSuperview()
                            // Alert the user
                            CommonUtils.showDefaultAlertToUser(self, title: "Server Error", alertContents: "We received an invalid response from the server. Please try again later!")
                        })
                        // Return
                        return
                    }
                    
                    let strStatus: String! = status as! String
                    let strReason: String? = jsonResponse["reason"] as? String
                    
                    if( ( strStatus == "not_invalidated" && strReason! == "no_match") ||
                        ( strStatus == "invalidation_successful" && strReason == nil ) ) {
                        
                        // Clean up Keychain
                        KeychainWrapper.defaultKeychainWrapper().setString("", forKey: "LocNotes-username")
                        KeychainWrapper.defaultKeychainWrapper().setString("", forKey: "LocNotes-loginToken")
                        KeychainWrapper.defaultKeychainWrapper().setDouble(0, forKey: "LocNotes-tokenExpiry")
                        KeychainWrapper.defaultKeychainWrapper().setBool(false, forKey: "LocNotes-userLoggedIn")
                        KeychainWrapper.defaultKeychainWrapper().setDouble(0, forKey: "LocNotes-userLoggedInAt")
                        // Set default settings
                        KeychainWrapper.defaultKeychainWrapper().setBool(false, forKey: "LocNotes-TouchIDEnabled")
                        KeychainWrapper.defaultKeychainWrapper().setBool(true, forKey: "LocNotes-PrefferedUploadMediumIsWiFi")
                        KeychainWrapper.defaultKeychainWrapper().setString("", forKey: "LocNotes-TouchIDBackupPwd")
                        // Also, clear up CoreData
                        self.clearUpCoreData()
                        
                        // Take the user to the login screen
                        dispatch_async(dispatch_get_main_queue(), {
                            self.loadingScreen.removeFromSuperview()
                            self.navigationController?.performSegueWithIdentifier("showNewUser", sender: self)
                        })
                        // And we're done
                        return
                        
                    } else {
                        // We've got issues
                        dispatch_async(dispatch_get_main_queue(), {
                            // Hide the loading screen
                            self.loadingScreen.removeFromSuperview()
                            // Alert the user
                            CommonUtils.showDefaultAlertToUser(self, title: "Server Error", alertContents: "We received an invalid response from the server. Please try again later!")
                        })
                        // Return
                        return
                    }
                    
                } catch {
                    // Tell the user that we couldn't log them out
                    dispatch_async(dispatch_get_main_queue(), {
                        // Hide the loading screen
                        self.loadingScreen.removeFromSuperview()
                        // Alert the user
                        CommonUtils.showDefaultAlertToUser(self, title: "Server Error", alertContents: "We received an invalid response from the server. Please try again later!")
                    })
                    // Return
                    return
                }
            })
            asyncTask.resume() // Start the task now
            // Return
            return
        })
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
        // Add the options to the Action Sheet
        actionSheet.addAction(deleteAction)
        actionSheet.addAction(cancelAction)
        // Now present the Action Sheet
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    // MARK: - CoreData related stuff
    func clearUpCoreData() {
        // Clear up CoreData; Delete it ALL :(
        
        if( self.managedContext == nil ) {
            self.managedContext = AppDelegate().managedObjectContext
        }
        
        let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "LocationLog")
        do {
            let results = try self.managedContext?.executeFetchRequest(fetchRequest)
            let locationLogs: [LocationLog] = results as! [LocationLog]
            
            // Iterate over them and see which one should be delete
            for locationLog in locationLogs {
                // Ask CoreData to delete
                self.managedContext?.deleteObject(locationLog)
                // Ask Context To Save It
                try self.managedContext?.save()
            }
        } catch {  }
        
        let imagesFetchRequest: NSFetchRequest = NSFetchRequest(entityName: "FullResolutionS3Image")
        do {
            let imageResults = try self.managedContext?.executeFetchRequest(imagesFetchRequest)
            let images: [FullResolutionS3Image] = imageResults as! [FullResolutionS3Image]
            
            // Iterate over them and see which one to delete
            for image in images {
                // Remove this image
                self.managedContext?.deleteObject(image)
                // Ask Context to save the changes
                try self.managedContext?.save()
            }
        } catch {  }
        
        let thumbnailFetchRequest: NSFetchRequest = NSFetchRequest(entityName: "ImageThumbnail")
        do {
            let thumbnailResults = try self.managedContext?.executeFetchRequest(thumbnailFetchRequest)
            let thumbnails: [ImageThumbnail] = thumbnailResults as! [ImageThumbnail]
            
            // Iterate over them and see which ones to delete
            for thumbnail in thumbnails {
                // Remove this thumbnail
                self.managedContext?.deleteObject(thumbnail)
                // Ask Context to save changes
                try self.managedContext?.save()
            }
        } catch {  }
    }
}
