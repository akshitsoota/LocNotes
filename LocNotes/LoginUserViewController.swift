//
//  LoginUserViewController.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/1/16.
//  Copyright © 2016 axe. All rights reserved.
//

import UIKit

class LoginUserViewController: UIViewController, UIGestureRecognizerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var signupButtonViewHolder: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    // Keeps track of the active field on the View
    var activeField: UITextField?
    // Keeps track of the loading screen that is shown
    var loadingScreen: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup the username and password fields
        setupUsernamePasswordFields()
        // Let us receive keyboard notifications
        registerForKeyboardNotifications()
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
        // Anddd, let us stop receiving those keyboard notifications
        deregisterFromKeyboardNotifications()
    }
    
    // MARK: - Keyboard Scroll Issues Fix
    // REFERENCE: http://stackoverflow.com/a/28813720/705471
    
    func registerForKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginUserViewController.keyboardWasShown(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginUserViewController.keyboardWillBeHidden(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func deregisterFromKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWasShown(notification: NSNotification) {
        // Need to calculate keyboard exact size due to Apple suggestions
        self.scrollView.scrollEnabled = true
        let info: NSDictionary = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size
        let contentInsets: UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize!.height + 20, 0.0)
        
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        
        var aRect: CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height
        if activeField != nil {
            if (!CGRectContainsPoint(aRect, activeField!.frame.origin)) {
                self.scrollView.scrollRectToVisible(activeField!.frame, animated: true)
            }
        }
    }
    
    func keyboardWillBeHidden(notification: NSNotification)
    {
        // Once keyboard disappears, restore original positions
        let info: NSDictionary = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size
        let contentInsets: UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, -keyboardSize!.height - 20, 0.0)
        
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        self.view.endEditing(true)
        self.scrollView.scrollEnabled = false
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        activeField = textField
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        activeField = nil
    }
    
    // MARK: - viewDidLoad() setup functions
    func setupUsernamePasswordFields() {
        // Remove the default border off the username and password fields
        self.usernameField.borderStyle = .None
        self.passwordField.borderStyle = .None
        
        // Initialize the bottom white border for the username field
        let usernameBorder = CALayer()
        let borderWidth = CGFloat(0.5)
        usernameBorder.borderColor = UIColor.whiteColor().CGColor
        usernameBorder.frame = CGRect(x: 0, y: self.usernameField.frame.size.height - borderWidth, width: self.usernameField.frame.size.width, height: self.usernameField.frame.size.height)
        usernameBorder.borderWidth = borderWidth
        
        // Similarly, set one up for the password field
        let passwordBorder = CALayer()
        passwordBorder.borderColor = UIColor.whiteColor().CGColor
        passwordBorder.frame = CGRect(x: 0, y: self.passwordField.frame.size.height - borderWidth, width: self.passwordField.frame.size.width, height: self.passwordField.frame.size.height)
        passwordBorder.borderWidth = borderWidth
        
        // Set it to both the fields now
        self.usernameField.layer.addSublayer(usernameBorder)
        self.usernameField.layer.masksToBounds = true
        
        self.passwordField.layer.addSublayer(passwordBorder)
        self.passwordField.layer.masksToBounds = true
        
        // Set password field to a secure entry field
        self.passwordField.secureTextEntry = true
        
        // Have all the return events come to us
        self.usernameField.delegate = self
        self.passwordField.delegate = self
    }
    
    // MARK: - Actions received here
    @IBAction func loginButtonClicked(sender: AnyObject) {
        // Cast the sender to a UIButton
        let senderButton: UIButton! = sender as! UIButton
        // Set the login button background back to the default
        senderButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        // Start the login process
        attemptLogin()
    }
    
    @IBAction func loginButtonPressedDown(sender: AnyObject) {
        let senderButton: UIButton! = sender as! UIButton
        // Now let us deal with the background of the sender button
        senderButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
    }
    
    @IBAction func loginButtonTouchCancelled(sender: AnyObject) {
        // Cast the sender to a UIButton
        let senderButton: UIButton! = sender as! UIButton
        // Set the login button background back to the default
        senderButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
    }
    
    @IBAction func signupButtonClicked(sender: AnyObject) {
        // Reset the background of the parent view
        signupButtonViewHolder.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        // Now perform the segue
        performSegueWithIdentifier("showSignupUser", sender: self)
    }
    
    @IBAction func signupButtonPressedDown(sender: AnyObject) {
        // Deal with the background of the parent view
        signupButtonViewHolder.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
    }
    
    @IBAction func signupButtonTouchCancelled(sender: AnyObject) {
        // Reset the background of the parent view
        signupButtonViewHolder.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if( textField == self.usernameField ) {
            self.passwordField.becomeFirstResponder() // Let the password field take over
        } else if( textField == self.passwordField ) {
            textField.resignFirstResponder() // Hide the keyboard
            attemptLogin() // Attempt to logon
        }
        // Anyways, return:
        return true
    }
    
    // MARK: - Backend functions here
    func attemptLogin() { 
        // Run basic validation tests
        if( !loginValidationTest() ) {
            return
        }
        // Fetch the values from the endpoints properties list
        // REFERENCE: http://www.kaleidosblog.com/nsurlsession-in-swift-get-and-post-data
        
        var keys: NSDictionary?
        
        if let path = NSBundle.mainBundle().pathForResource("endpoints", ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)
        }
        if let dict = keys {
            let awsEndpoint: String! = dict["awsEC2EndpointURL"] as! String
            let loginURL: String! = dict["loginUserURL"] as! String
            
            // Fetch the loading screen
            if( loadingScreen == nil ) {
                loadingScreen = CommonUtils.returnLoadingScreenView(self)
            }
            // Now setup the loading screen
            CommonUtils.setLoadingTextOnLoadingScreenView(self.loadingScreen, newLabelContents: "Connecting to the server...")
            // Add it to the view
            self.view.addSubview(loadingScreen)
            
            // Now start the async request
            let asyncRequestURL: NSURL! = NSURL(string: "http://" + awsEndpoint + loginURL)
            let asyncSession: NSURLSession! = NSURLSession.sharedSession()
            
            let asyncRequest: NSMutableURLRequest! = NSMutableURLRequest(URL: asyncRequestURL)
            asyncRequest.HTTPMethod = "POST"
            asyncRequest.cachePolicy = .ReloadIgnoringLocalCacheData
            asyncRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
            // Let us form a dictionary of <K, V> pairs to be sent
            // REFERENCE: http://stackoverflow.com/a/28009796/705471
            let requestParams: Dictionary<String, String>! = ["username": usernameField.text!,
                                                              "password": passwordField.text!]
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
            
            // DEPRECATED: requestBody = requestBody.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
            requestBody = requestBody.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
            asyncRequest.HTTPBody = requestBody.dataUsingEncoding(NSUTF8StringEncoding)
            
            let asyncTask = asyncSession.dataTaskWithRequest(asyncRequest, completionHandler: loginResponseReceived)
            asyncTask.resume() // Start the task now
            // Return
            return
        }
        
        // Else, we've got a problem
        dispatch_async(dispatch_get_main_queue(), {
            self.loadingScreen.removeFromSuperview() // Hide the loading screen
            CommonUtils.showDefaultAlertToUser(self, title: "Internal Error", alertContents: "There was an internal error in fetching our backend endpoint. Please try again!")
        })
        // Return
        return
    }
    
    func loginResponseReceived(data: NSData?, response: NSURLResponse?, error: NSError?) -> () {
        // Process the JSON data here if we got no errors
        if( error != nil ) {
            // Deal with the error here
            dispatch_async(dispatch_get_main_queue(), {
                self.loadingScreen.removeFromSuperview() // Hide the loading screen
                // Show an alert to the user
                CommonUtils.showDefaultAlertToUser(self, title: "Network Error", alertContents: "Your request could not be fulfilled. Please try logging in again!")
            })
            // Return
            return
        }
        
        do {
            
            let jsonResponse: [String: AnyObject] = try (NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions()) as? [String: AnyObject])!
            // Now process the response
            let status = jsonResponse["status"]
            
            if( status == nil ) {
                dispatch_async(dispatch_get_main_queue(), {
                    self.loadingScreen.removeFromSuperview() // Hide the loading screen
                    // We've got some problems parsing the response; Show an alert to the user
                    CommonUtils.showDefaultAlertToUser(self, title: "Network Error", alertContents: "The server returned an invalid response. Please try logging in again!")
                })
                // Return
                return
            }
            
            let strStatus: String! = status as! String
            
            if( strStatus == "no_match" ) {
                dispatch_async(dispatch_get_main_queue(), {
                    self.loadingScreen.removeFromSuperview() // Hide the loading screen
                    // No matching account was found; Show an alert to the user
                    CommonUtils.showDefaultAlertToUser(self, title: "Validation Error", alertContents: "You've entered invalid credentials. Please fix them and try logging in again!")
                })
                // Return
                return
            } else if( strStatus == "correct_credentials_old_token_passed" || strStatus == "correct_credentials_new_token_generated" ) {
                // Save all the information given by the server
                let loginToken: String! = jsonResponse["login_token"] as! String
                let tokenExpiry: Double! = (jsonResponse["token_expiry"] as? NSNumber)?.doubleValue
                
                // Update the loading screen
                dispatch_async(dispatch_get_main_queue(), {
                    CommonUtils.setLoadingTextOnLoadingScreenView(self.loadingScreen, newLabelContents: "Saving your user credentials...")
                })
                
                // Call the Keychain Wrapper
                let usernameSaved: Bool = KeychainWrapper.defaultKeychainWrapper().setString(usernameField.text!, forKey: "LocNotes-username")
                let loginTokenSaved: Bool = KeychainWrapper.defaultKeychainWrapper().setString(loginToken, forKey: "LocNotes-loginToken")
                let tokenExpirySaved: Bool = KeychainWrapper.defaultKeychainWrapper().setDouble(tokenExpiry, forKey: "LocNotes-tokenExpiry")
                let userLoggedInSaved: Bool = KeychainWrapper.defaultKeychainWrapper().setBool(true, forKey: "LocNotes-userLoggedIn")
                let userLoggedInAtSaved: Bool = KeychainWrapper.defaultKeychainWrapper().setDouble(NSDate().timeIntervalSince1970, forKey: "LocNotes-userLoggedInAt")
                
                let savedAll: Bool = usernameSaved && loginTokenSaved && tokenExpirySaved && userLoggedInSaved && userLoggedInAtSaved
                
                // Check if we were able to save it all in Keychain
                if( !savedAll ) {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.loadingScreen.removeFromSuperview() // Hide the loading screen
                        // We've got to tell the user; Show an alert
                        CommonUtils.showDefaultAlertToUser(self, title: "Internal Error", alertContents: "You were successfully logged in but we were unable to save your login credentials in Keychain! Please try again later.")
                    })
                    // Return
                    return
                } else {
                    // Timer to switch out to the logged in user; Spawn it off in the main thread
                    dispatch_async(dispatch_get_main_queue(), {
                        _ = NSTimer.scheduledTimerWithTimeInterval(
                            2, target: self, selector: #selector(LoginUserViewController.switchOutToListScreen), userInfo: nil, repeats: false
                        )
                    })
                }
            }
            
            
        } catch {
            dispatch_async(dispatch_get_main_queue(), {
                self.loadingScreen.removeFromSuperview() // Hide the loading screen
                // We've got some problems parsing the response; Show an alert to the user
                CommonUtils.showDefaultAlertToUser(self, title: "Network Error", alertContents: "The server returned an invalid response. Please try to login again!")
            })
            // Return
            return
        }
    }
    
    func switchOutToListScreen() {
        // Switch out to the next screen
        self.performSegueWithIdentifier("showLoggedInUserFromLogin", sender: self)
    }
    
    // MARK: - Login Validation Tests
    func loginValidationTest() -> Bool! {
        // Hide the keyboard if visible
        self.view.endEditing(true)
        
        // Username field test
        let trimmedUsername: String! = usernameField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if( trimmedUsername.characters.count < 5 ) {
            CommonUtils.showDefaultAlertToUser(self, title: "Validation Error", alertContents: "Username must atleast be 5 characters long. Please enter a valid username to proceed with logging in!")
            // Return
            return false
        }
        
        if trimmedUsername.characters.indexOf(" ") != nil {
            CommonUtils.showDefaultAlertToUser(self, title: "Validation Error", alertContents: "Usernames cannot have spaces. Please remove any unnecessary spaces and try again!")
            // Return
            return false
        }
        
        // Password field test
        if( passwordField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.count < 8 ) {
            CommonUtils.showDefaultAlertToUser(self, title: "Validation Error", alertContents: "Passwords must atleast be 8 characters long. Please fix your password and try again!")
            // Return
            return false
        }
        
        // Return true
        return true
    }
    
    // MARK: - Segue operations
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Check which Segue is it
        if( segue.identifier == "showLoggedInUserFromLogin" ) {
            // Set the necessary information
            let destVC: UserLocationLogsViewController = segue.destinationViewController.childViewControllers[0] as! UserLocationLogsViewController
            destVC.calledFromLoginOrSignUp = true
        }
    }
    
    // MARK: - Helper functions here
    
    // REFERENCE: http://stackoverflow.com/a/29534779/705471
    func resizeImage(image: UIImage, newHeight: CGFloat) -> UIImage {
        let scale = newHeight / image.size.height
        let newWidth = image.size.width * scale
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(newWidth, newHeight), false, 0)
        image.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        // Return now
        return newImage
    }
}
