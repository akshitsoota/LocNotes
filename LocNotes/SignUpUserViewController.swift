//
//  SignUpUserViewController.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/2/16.
//  Copyright © 2016 axe. All rights reserved.
//

import UIKit

class SignUpUserViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButtonViewHolder: UIView!
    // Keeps track of the active field on the View
    var activeField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup the fields
        setupFields()
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
    
    // MARK: - Force Screen Orientation
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    // MARK: - Keyboard Scroll Issues Fix
    // REFERENCE: http://stackoverflow.com/a/28813720/705471
    
    func registerForKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SignUpUserViewController.keyboardWasShown(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SignUpUserViewController.keyboardWillBeHidden(_:)), name: UIKeyboardWillHideNotification, object: nil)
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
    func setupFields() {
        // Remove the default border off the username and password fields
        self.nameField.borderStyle = .None
        self.emailField.borderStyle = .None
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
        
        // Similarly, set one up for the name field
        let nameBorder = CALayer()
        nameBorder.borderColor = UIColor.whiteColor().CGColor
        nameBorder.frame = CGRect(x: 0, y: self.nameField.frame.size.height - borderWidth, width: self.nameField.frame.size.width, height: self.nameField.frame.size.height)
        nameBorder.borderWidth = borderWidth
        
        // Similarly, set one up for the email field
        let emailBorder = CALayer()
        emailBorder.borderColor = UIColor.whiteColor().CGColor
        emailBorder.frame = CGRect(x: 0, y: self.emailField.frame.size.height - borderWidth, width: self.emailField.frame.size.width, height: self.emailField.frame.size.height)
        emailBorder.borderWidth = borderWidth
        
        // Set it to both the fields now
        self.usernameField.layer.addSublayer(usernameBorder)
        self.usernameField.layer.masksToBounds = true
        
        self.passwordField.layer.addSublayer(passwordBorder)
        self.passwordField.layer.masksToBounds = true
        
        self.nameField.layer.addSublayer(nameBorder)
        self.nameField.layer.masksToBounds = true
        
        self.emailField.layer.addSublayer(emailBorder)
        self.emailField.layer.masksToBounds = true
        
        // Set password field to a secure entry field
        self.passwordField.secureTextEntry = true
        
        // Have all the return events come to us
        self.usernameField.delegate = self
        self.passwordField.delegate = self
        self.nameField.delegate = self
        self.emailField.delegate = self
    }
    
    // MARK: - Actions received here
    @IBAction func signupButtonClicked(sender: AnyObject) {
        // Cast the sender to a UIButton
        let senderButton: UIButton! = sender as! UIButton
        // Set the signup button background back to the default
        senderButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        // Start the signup process
        attemptSignup()
    }
    
    @IBAction func signupButtonPressedDown(sender: AnyObject) {
        let senderButton: UIButton! = sender as! UIButton
        // Now let us deal with the background of the sender button
        senderButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
    }
    
    @IBAction func signupButtonTouchCancelled(sender: AnyObject) {
        // Cast the sender to a UIButton
        let senderButton: UIButton! = sender as! UIButton
        // Set the signup button background back to the default
        senderButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
    }
    
    @IBAction func loginButtonClicked(sender: AnyObject) {
        // Reset the background of the parent view
        loginButtonViewHolder.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        // Now perform the segue
        performSegueWithIdentifier("showLoginUser", sender: self)
    }
    
    @IBAction func loginButtonTouchCancelled(sender: AnyObject) {
        // Reset the background of the parent view
        loginButtonViewHolder.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
    }
    
    @IBAction func loginButtonPressedDown(sender: AnyObject) {
        // Deal with the background of the parent view
        loginButtonViewHolder.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if( textField == self.nameField ) {
            self.emailField.becomeFirstResponder() // Let the email field take over
        } else if( textField == self.emailField ) {
            self.usernameField.becomeFirstResponder() // Let the username field take over
        } else if( textField == self.usernameField ) {
            self.passwordField.becomeFirstResponder() // Let the password field take over
        } else if( textField == self.passwordField ) {
            self.passwordField.resignFirstResponder() // Hide the keyboard
            attemptSignup() // Start the sign up process
        }
        // Anyways, return:
        return true
    }
    
    func attemptSignup() {
        // Run basic validation tests
        if( !signupValidationTests() ) {
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
            let signupURL: String! = dict["signupUserURL"] as! String
            
            // Fetch the loading screen
            let loadingScreen: UIView? = CommonUtils.returnLoadingBlurredView(self)
            if loadingScreen != nil {
                self.view.addSubview(loadingScreen!)
            } else {
                // TODO:
            }
            
            // Now start the async request
            let asyncRequestURL: NSURL! = NSURL(string: "http://" + awsEndpoint + signupURL)
            let asyncSession: NSURLSession! = NSURLSession.sharedSession()
            
            let asyncRequest: NSMutableURLRequest! = NSMutableURLRequest(URL: asyncRequestURL)
            asyncRequest.HTTPMethod = "POST"
            asyncRequest.cachePolicy = .ReloadIgnoringLocalCacheData
            asyncRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
            // Let us form a dictionary of <K, V> pairs to be sent
            // REFERENCE: http://stackoverflow.com/a/28009796/705471
            let requestParams: Dictionary<String, String>! = ["fullname": nameField.text!,
                                                              "emailadd": emailField.text!,
                                                              "username": usernameField.text!,
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
            
            requestBody = requestBody.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
            asyncRequest.HTTPBody = requestBody.dataUsingEncoding(NSUTF8StringEncoding)
            
            let asyncTask = asyncSession.dataTaskWithRequest(asyncRequest) {
                data, response, error in
                // Processing here
            }
            asyncTask.resume() // Start the task now
        }
        
        // Else, we've got a problem
        // TODO:
    }
    
    // MARK: - Signup Validation Tests
    func signupValidationTests() -> Bool! {
        // Full Name Field test
        if( nameField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.count == 0 ) {
            let alert = UIAlertController(title: "Validation Error", message: "Name cannot be empty. Please enter your full name to proceed!", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            // Return
            return false
        }
        // Email Address Field test
        if( !isValidEmail(emailField.text!) ) {
            let alert = UIAlertController(title: "Validation Error", message: "The email that you've entered is not valid. Please enter a valid email address to proceed!", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            // Return
            return false
        }
        // Username field test
        let trimmedUsername: String! = usernameField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if( trimmedUsername.characters.count < 5 ) {
            let alert = UIAlertController(title: "Validation Error", message: "Username must atleast be 5 characters long. Please enter a valid username to proceed with registering!", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            // Return
            return false
        }
        
        if trimmedUsername.characters.indexOf(" ") != nil {
            let alert = UIAlertController(title: "Validation Error", message: "Usernames cannot have spaces. Please remove any unnecessary spaces and try again!", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            // Return
            return false
        }
        
        // Password field test
        if( passwordField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.count < 8 ) {
            let alert = UIAlertController(title: "Validation Error", message: "Passwords must atleast be 8 characters long. Please fix your password and try again!", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            // Return
            return false
        }
        
        // Return true
        return true
    }
    
    func isValidEmail(testStr:String) -> Bool {
        // print("validate calendar: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
    }

}
