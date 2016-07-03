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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the status br color to the light color
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        // Setup the username and password fields
        setupUsernamePasswordFields()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        // Set the status bar color back to default
        UIApplication.sharedApplication().statusBarStyle = .Default
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
        signupButtonViewHolder.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
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
    
    func attemptLogin() {
        // TODO: Start the login procedure
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
