//
//  NewUserLocationLogViewController.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/7/16.
//  Copyright © 2016 axe. All rights reserved.
//

import AWSCore
import AWSS3

import CoreData
import MapKit
import Photos
import UIKit

class NewUserLocationLogViewController: UIViewController, UITextViewDelegate, UICollectionViewDataSource,
                                        UINavigationControllerDelegate, UIImagePickerControllerDelegate,
                                        UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource,
                                        UITextFieldDelegate
{

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var titleTextFieldHolder: UIView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextFieldHolder: UIView!
    @IBOutlet weak var descriptionTextField: UITextView!
    @IBOutlet weak var logPhotosMainHolder: UIView!
    @IBOutlet weak var logPhotosMainScrollView: UIScrollView!
    @IBOutlet weak var logPhotosCollectionView: UICollectionView!
    @IBOutlet weak var locationsUserVisitedHolder: UIView!
    @IBOutlet weak var locationVisitedTable: UITableView!
    @IBOutlet weak var locationsVisitedAddNewButton: UIButton!
    @IBOutlet weak var locationsVisitedRemoveMultipleButton: UIButton!
    @IBOutlet weak var locationsVisitedReorderLocationsButton: UIButton!
    @IBOutlet weak var locationsVisitedStopActionButton: UIButton!
    // The Description Field default placeholder text
    var defaultDescriptionTextFieldPlaceholder: String!
    // Default placeholder color for the Description Text Field
    var defaultDescriptionTextFieldPlaceholderColor: UIColor!
    // Holds the PhotoViews shown in the CollectionView
    var photoViews: [PhotoView] = []
    // ImagePicker for the user to pick pictures from the saved photos
    var imagePicker = UIImagePickerController()
    // Holds the locations the user visited
    var locationsUserVisited: [MKMapItem] = []
    // Holds what action is happening in Locations Visited Table
    var locationsVisitedTableAction: Int = -1 // -1 = Nothing; 0 = Multi-Remove; 1 = Re-order mode
    // Loading Progress View
    var loadingProgressView: ProgressLoadingScreenView!
    // Keeps track of the active field on the View
    var activeField: UIView?
    
    // Dispatch Queues
    let uploadLocationLogQueue = dispatch_queue_create("LocationLogUploadQueue", DISPATCH_QUEUE_CONCURRENT)
    // Core Data Managed Context
    var managedContext: NSManagedObjectContext?
    
    // Amazon S3 Upload Status
    var cancelFuture: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup view
        setupView()
        // Setup CoreData
        setupCoreData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // Set the status bar color to the light color
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        // Let us receive keyboard notifications
        registerForKeyboardNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        // Set the status bar color back to default
        UIApplication.sharedApplication().statusBarStyle = .Default
        // Anddd, let us stop receiving those keyboard notifications
        deregisterFromKeyboardNotifications()
    }
    
    // MARK: - Setup functions
    func setupView() {
        // Custom functions
        func generateTopBorder(forView: UIView!) {
            let topBorder: UIView = UIView(frame: CGRectMake(0, 0, forView.frame.size.width, 1))
            topBorder.backgroundColor = UIColor.darkGrayColor()
            // Add it
            forView.addSubview(topBorder)
        }
        
        func generateBottomBorder(forView: UIView!) {
            let bottomBorder: UIView = UIView(frame: CGRectMake(0, forView.frame.size.height - 1, forView.frame.size.width, 1))
            bottomBorder.backgroundColor = UIColor.darkGrayColor()
            // Add it
            forView.addSubview(bottomBorder)
        }
        
        // Add the top border for the field holders
        generateTopBorder(self.titleTextFieldHolder)
        generateTopBorder(self.descriptionTextFieldHolder)
        generateTopBorder(self.logPhotosMainHolder)
        generateTopBorder(self.locationsUserVisitedHolder)
        // Add the bottom border for the field holders
        generateBottomBorder(self.titleTextFieldHolder)
        generateBottomBorder(self.descriptionTextFieldHolder)
        generateBottomBorder(self.logPhotosMainHolder)
        generateBottomBorder(self.locationsUserVisitedHolder)
        
        // Let us handle the text view events to deal with the placeholder text
        self.defaultDescriptionTextFieldPlaceholder = self.descriptionTextField.text
        self.defaultDescriptionTextFieldPlaceholderColor = self.descriptionTextField.textColor
        self.descriptionTextField.delegate = self
        
        // Setup the background color for the CollectionView
        self.logPhotosCollectionView.backgroundColor = UIColor.clearColor()
        self.logPhotosCollectionView.backgroundView = UIView(frame: CGRectZero)
        // Let us handle the data source and delegate for the CollectionView of the photos
        self.logPhotosCollectionView.dataSource = self
        // We should handle the FlowLayout for the Photos CollectionView as well
        self.logPhotosCollectionView.delegate = self
        
        // Setup the Locations Visited Table View
        self.locationVisitedTable.dataSource = self
        self.locationVisitedTable.delegate = self
        
        // Hide stop action button in Locations Visited by default
        self.locationsVisitedStopActionButton.hidden = true
        
        // Have all events come to us
        self.titleTextField.delegate = self
        
        // If user taps outside any field, we are to dismiss the keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(NewUserLocationLogViewController.dismissKeyboard))
        self.view.addGestureRecognizer(tap)
    }
    
    func setupCoreData() {
        dispatch_sync(self.uploadLocationLogQueue) {
            self.managedContext = AppDelegate().managedObjectContext
        }
    }
    
    // MARK: - Keyboard Scroll Issues Fix
    // REFERENCE: http://stackoverflow.com/a/28813720/705471
    
    func registerForKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewUserLocationLogViewController.keyboardWasShown(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewUserLocationLogViewController.keyboardWillBeHidden(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func deregisterFromKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWasShown(notification: NSNotification) {
        // Need to calculate keyboard exact size due to Apple suggestions
        let info: NSDictionary = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size
        let contentInsets: UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize!.height, 0.0)
        
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
    
    func keyboardWillBeHidden(notification: NSNotification) {
        // Once keyboard disappears, restore original positions
        let info: NSDictionary = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size
        var scrollViewFrame: CGRect = self.scrollView.frame
        
        // Begin animation
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(0.3)
        
        scrollViewFrame.size.height += (keyboardSize?.height)!
        // Apply it
        self.scrollView.frame = scrollViewFrame
        // Now animate
        UIView.commitAnimations()
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        self.activeField = textField
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        self.activeField = nil
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    // MARK: - TextView Delegate functions to deal with placeholder text and keyboard actions
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        self.activeField = textView
        return true
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        if( textView == descriptionTextField &&
            textView.textColor == defaultDescriptionTextFieldPlaceholderColor ) {
            
            textView.text = nil
            textView.textColor = UIColor.blackColor()
        }
    }
    
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        self.activeField = nil
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if( textView == descriptionTextField &&
            textView.text.isEmpty ) {
            
            textView.text = defaultDescriptionTextFieldPlaceholder
            textView.textColor = defaultDescriptionTextFieldPlaceholderColor
        }
        // Remove active field as well
        self.activeField = nil
    }
    
    // MARK: - TextField return key functions dealt with here
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if( textField == self.titleTextField ) {
            self.descriptionTextField.becomeFirstResponder() // Let the description field take over
        }
        // Anyways, return:
        return false
    }
    
    // MARK: - PhotoCollectionView Functions
    func addPhotoButtonClicked(sender: AnyObject) -> Void {
        // Setup the Image Picker
        self.imagePicker.delegate = self
        // Allow the user to pick photos now; Check for authorization now
        if PHPhotoLibrary.authorizationStatus() != .Authorized {
            // Complain as we don't have access:
            // Attempt to gain access
            PHPhotoLibrary.requestAuthorization({(authStatus: PHAuthorizationStatus) in
                // Again, check if we've got access
                if( authStatus != PHAuthorizationStatus.Authorized ) {
                    // Complain; Setup the Alert Controller
                    let alertController: UIAlertController = UIAlertController(title: "Attention", message: "Please allow us to access your photo library in the Settings so that you can pick and add photos to your location log. Goto settings?", preferredStyle: .Alert)
                    
                    // Setup the Action Buttons for the Alert
                    let settingsAction: UIAlertAction = UIAlertAction(title: "Settings", style: .Default) {(_) -> Void in
                        let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
                        if let url = settingsUrl {
                            UIApplication.sharedApplication().openURL(url)
                        }
                    }
                    let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
                    
                    // Now attach the action buttons to the Alert Controller
                    alertController.addAction(settingsAction)
                    alertController.addAction(cancelAction)
                    
                    // Now show it; on the main thread
                    dispatch_async(dispatch_get_main_queue(), {
                        self.presentViewController(alertController, animated: true, completion: nil)
                    })
                } else {
                    // We've got access to their photos, so:
                    if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
                        // Setup some things up
                        self.imagePicker.sourceType = .PhotoLibrary
                        self.imagePicker.allowsEditing = false
                        
                        // Now present the controller; but on the main thread
                        dispatch_async(dispatch_get_main_queue(), {
                            self.presentViewController(self.imagePicker, animated: true, completion: nil)
                        })
                    }
                }
            })
        } else {
            // We have access to their photos
            if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
                // Setup some things up
                imagePicker.delegate = self
                imagePicker.sourceType = .PhotoLibrary
                imagePicker.allowsEditing = false
                // Now present the controller
                self.presentViewController(imagePicker, animated: true, completion: nil)
            }
        }
    }
    
    func removePhotoButtonClicked(sender: AnyObject, extraInfo: PhotoView?) -> Void {
        if( extraInfo == nil ) {
            return // We cannot do anything :(
        }
        // Ask the user if he really wants to delete his photo from our Photo CollectionView list
        let actionSheet: UIAlertController = UIAlertController(title: nil, message: "Are you sure you want to remove your photo from the location log?", preferredStyle: .ActionSheet)
        let deleteAction: UIAlertAction = UIAlertAction(title: "Delete", style: .Destructive, handler: {(alert: UIAlertAction) -> Void in
            
            // Fetch the index and remove the PhotoView at that index
            self.photoViews.removeAtIndex(extraInfo!.photoViewIndex)
            // Update all the PhotoView indexes
            if( self.photoViews.count != 0 ) {
                for index in 0...(self.photoViews.count - 1) {
                    self.photoViews[index].photoViewIndex = index
                }
            }
            // Force update of the CollectionView
            self.logPhotosCollectionView.reloadData()
            
        })
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
        // Add the options to the Action Sheet
        actionSheet.addAction(deleteAction)
        actionSheet.addAction(cancelAction)
        // Now present the Action Sheet
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    func imageClicked(sender: AnyObject, extraInfo: PhotoView?) -> Void {
        // Nothing as of now
    }
    
    // MARK: - ImagePickerController Delegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        // Hide the ImagePicker
        self.dismissViewControllerAnimated(true, completion: {() -> Void in
            // Do nothing
        })
        // Now, save the image
        let referenceURL: NSURL = info[UIImagePickerControllerReferenceURL] as! NSURL
        let fetchResult: PHFetchResult = PHAsset.fetchAssetsWithALAssetURLs([referenceURL], options: nil)
        let photoAsset: PHAsset = fetchResult.firstObject as! PHAsset
        // Check for the image location
        let photoLocation: CLLocation? = photoAsset.location
        // Now save the image
        let newPhotoView: PhotoView = PhotoView()
        newPhotoView.assetsLocation = referenceURL // Save the reference URL that we received
        newPhotoView.photoAsset = photoAsset // Save the PhotoAsset that we resolved
        newPhotoView.photoLocation = photoLocation // Save the location that the photo was taken
        newPhotoView.photoViewIndex = self.photoViews.count // Add the photo view index
        // Resize the image for thumbnail view and save it in the PhotoView
        func resizeImage(image: UIImage, newHeight: CGFloat) -> UIImage {
            let scale = newHeight / image.size.height
            let newWidth = image.size.width * scale
            UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
            image.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
            let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return newImage
        }
        
        newPhotoView.thumbnailImage = resizeImage(info[UIImagePickerControllerOriginalImage] as! UIImage, newHeight: 128)
        // Add it tot the list of PhotoViews
        self.photoViews.append(newPhotoView)
        // Now force an update of the CollectionView
        self.logPhotosCollectionView.reloadData()
        // Scroll to end of the PhotosCollectionView
        let lastIndexPath: NSIndexPath = NSIndexPath(forItem: self.photoViews.count, inSection: 0)
        self.logPhotosCollectionView.scrollToItemAtIndexPath(lastIndexPath, atScrollPosition: .Right, animated: true)
    }
    
    // MARK: - UICollectionViewDataSource Delegate
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Add one to the number of PhotoViews (the one extra is for the plus button collection view)
        return (self.photoViews.count + 1)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // Check if we should be returning a default PhotoView cell or a plus button CollectionView
        if( indexPath.row == self.photoViews.count ) {
            let addPhotoCell: AddNewPhotoCollectionViewCell? = collectionView.dequeueReusableCellWithReuseIdentifier("addPhotoCell", forIndexPath: indexPath) as? AddNewPhotoCollectionViewCell
            // Customize the cell
            addPhotoCell?.addPhotoButtonClickedFunction = self.addPhotoButtonClicked
            // Now, return
            return addPhotoCell!
        }
        // Else, we are returning a normal PhotoViewCell
        var photoViewCell: PhotoCollectionViewCell! = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        // Check for null
        if( photoViewCell == nil ) {
            photoViewCell = PhotoCollectionViewCell(frame: CGRect(x: 0, y: 0, width: 128, height: 128))
        }
        // Customize the cell
        photoViewCell?.extraInformation = self.photoViews[indexPath.row]
        photoViewCell?.imageViewClickedFunction = self.imageClicked
        photoViewCell?.removePhotoButtonClickedFunction = self.removePhotoButtonClicked
        // Now return
        return photoViewCell!
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout Delegate
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        // REFERENCE: http://stackoverflow.com/a/29987062/705471
        
        if( indexPath.row == self.photoViews.count ) {
            // If we're asked for the size of the add photo button, default 128x128 is sent
            return CGSize(width: 128, height: 128)
        }
        // Else, calculate the ratio and then send the new size
        return CGSize(width: self.photoViews[indexPath.row].thumbnailImage!.size.width, height: 128)
    }
    
    // MARK: - UITableViewDelegate and UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.locationsUserVisited.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Return the location that the user visited
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("locationCell")!
        cell.textLabel?.text = self.locationsUserVisited[indexPath.row].placemark.title!
        
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // User wants to delete a TableView cell
            if self.locationsVisitedTableAction == 0 {
                // User is in Multi-Delete mode. This means, we've got an implicit confirmation, so delete it right away:
                //
                // Update the array
                self.locationsUserVisited.removeAtIndex(indexPath.row)
                // Show the deletion animation
                self.locationVisitedTable.beginUpdates()
                self.locationVisitedTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                self.locationVisitedTable.endUpdates()
            } else {
                // Prompt Action Sheet
                
                // Ask the user if he really wants to delete this location from the list of locations they've visited
                let actionSheet: UIAlertController = UIAlertController(title: nil, message: "Are you sure you want to delete this location from the list of locations you've visited for this location log?", preferredStyle: .ActionSheet)
                let deleteAction: UIAlertAction = UIAlertAction(title: "Delete", style: .Destructive, handler: {(alert: UIAlertAction) -> Void in
                    
                    // Update the array
                    self.locationsUserVisited.removeAtIndex(indexPath.row)
                    // Show the deletion animation
                    self.locationVisitedTable.beginUpdates()
                    self.locationVisitedTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                    self.locationVisitedTable.endUpdates()
                    
                })
                let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
                // Add the options to the Action Sheet
                actionSheet.addAction(deleteAction)
                actionSheet.addAction(cancelAction)
                // Now present the Action Sheet
                self.presentViewController(actionSheet, animated: true, completion: nil)
            }
        }
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if( self.locationsVisitedTableAction == 1 ) {
            return .None    // Re-ordering mode so we don't want to show the delete button
        }
        return .Delete      // Delete mode so we gotta show the minus signs to the left
    }
    
    func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if( self.locationsVisitedTableAction == 1 ) {
            return false    // As re-ordering is taking place, we don't want to left indent the items
        }
        return true         // Else, return true as the user is in delete mode
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        // Table re-ordering is taking place
        let objectMoved: MKMapItem = self.locationsUserVisited[sourceIndexPath.row]
        self.locationsUserVisited.removeAtIndex(sourceIndexPath.row)
        self.locationsUserVisited.insert(objectMoved, atIndex: destinationIndexPath.row)
        // Refresh the data
        self.locationVisitedTable.reloadData()
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Check if the user is re-ordering or not
        return (self.locationsVisitedTableAction == 1)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // We don't need to do anything if the user taps on a table cell but hide the fact that he tapped it
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: - Location You Visited Actions here
    @IBAction func addNewLocationVisitedClicked(sender: AnyObject) {
        // Goto the page where the user can add more locations
        self.performSegueWithIdentifier("showAddLocationToLog", sender: self)
    }
    
    @IBAction func removeLocationClicked(sender: AnyObject) {
        // Set state
        self.locationsVisitedTableAction = 0 // Multi-Remove taking place
        // Toggle editing mode on for the TableView
        self.locationVisitedTable.setEditing(true, animated: true)
        // Hide other buttons and show stop action button
        self.locationsVisitedStopActionButton.hidden = false
        self.locationsVisitedReorderLocationsButton.hidden = true
        self.locationsVisitedRemoveMultipleButton.hidden = true
        self.locationsVisitedAddNewButton.hidden = true
        // Force a table reload
        self.locationVisitedTable.reloadData()
    }
    
    @IBAction func moveRowsLocationsVisitedClicked(sender: AnyObject) {
        // Set state
        self.locationsVisitedTableAction = 1 // Table re-ordering requested
        // Toggle editing mode on the TableView
        self.locationVisitedTable.setEditing(true, animated: true)
        // Hide the other buttons and show the stop action button
        self.locationsVisitedStopActionButton.hidden = false
        self.locationsVisitedReorderLocationsButton.hidden = true
        self.locationsVisitedRemoveMultipleButton.hidden = true
        self.locationsVisitedAddNewButton.hidden = true
        // Force a table reload
        self.locationVisitedTable.reloadData()
    }
    
    @IBAction func stopCurrentActionLocationsVisitedClicked(sender: AnyObject) {
        // See what action is happening
        if self.locationsVisitedTableAction != (-1) {
            // Toggle it off
            self.locationVisitedTable.setEditing(false, animated: true)
            // Show other buttons and hide the stop action button
            self.locationsVisitedStopActionButton.hidden = true
            self.locationsVisitedReorderLocationsButton.hidden = false
            self.locationsVisitedRemoveMultipleButton.hidden = false
            self.locationsVisitedAddNewButton.hidden = false
        }
        // At the end, set unknown state
        self.locationsVisitedTableAction = -1 // Unknown state
    }
    
    // MARK: - Navigation Bar Actions here
    @IBAction func cancelLogClicked(sender: AnyObject) {
        // Check if the user has made any changes
        if( self.titleTextField.text?.isEmpty == false || self.descriptionTextField.text != self.defaultDescriptionTextFieldPlaceholder ||
            self.photoViews.count != 0 || self.locationsUserVisited.count != 0 ) {
            
            // Ask the user if he really wants to exit?
            let actionSheet: UIAlertController = UIAlertController(title: nil, message: "Are you sure you want to discard changes to your location log?", preferredStyle: .ActionSheet)
            let deleteAction: UIAlertAction = UIAlertAction(title: "Discard", style: .Destructive, handler: {(alert: UIAlertAction) -> Void in
                self.performSegueWithIdentifier("unwindSegueToLocationLogListing", sender: self)
            })
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
            // Add the options to the Action Sheet
            actionSheet.addAction(deleteAction)
            actionSheet.addAction(cancelAction)
            // Now present the Action Sheet
            self.presentViewController(actionSheet, animated: true, completion: nil)
            
        } else {
            
            // Just go back as usual
            self.performSegueWithIdentifier("unwindSegueToLocationLogListing", sender: self)
            
        }
    }
    
    @IBAction func doneLogClicked(sender: AnyObject) {
        
        // Hide the keyboard if visible
        self.view.endEditing(true)
        
        // STEP: Run Validation on the Location Log before we proceed with the submission
        if( !locationLogSubmissionValidationTests() ) {
            return              // Tests failed
        }
        // STEP: Check for an internet connection
        var preferredWifi: Bool? = KeychainWrapper.defaultKeychainWrapper().boolForKey("LocNotes-PrefferedUploadMediumIsWiFi")
        if( preferredWifi == nil ) {
            // Save one and proceed
            KeychainWrapper.defaultKeychainWrapper().setBool(true, forKey: "LocNotes-PrefferedUploadMediumIsWiFi")
            preferredWifi = true
        }
        
        let connectionType: CommonUtils.ConnectionStatus = CommonUtils.findIntentConnectionType()
        if( connectionType == CommonUtils.ConnectionStatus.ConnectionTypeCellular && preferredWifi! ) {
            // Tell the user that we plan to queue it up for later
            // TODO: Warn user, queue it up, take him back and update the screen
            // Return
            return
        }
        
        // Show the loading view
        if( self.loadingProgressView != nil ) {
            self.loadingProgressView.removeFromSuperview()      // If it is visible SOMEHOW
        }
        self.loadingProgressView = CommonUtils.returnProgressLoadingScreenView(self, size: UIScreen.mainScreen().bounds)
        self.navigationController?.view.addSubview(self.loadingProgressView)
        
        // Setup the loading view
        self.loadingProgressView.loadingProgressIndicator.startAnimating()
        self.loadingProgressView.loadingProgressLabel.text = "Preparing to save your Location Log in the cloud..."
        self.loadingProgressView.loadingProgressBar.progress = 0
        
        // By default, we want the upload to progress through
        self.cancelFuture = false
        
        // Create temporary directory for our Amazon S3 Uploads
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(
                NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("amazons3upload"),
                withIntermediateDirectories: true,
                attributes: nil)
        } catch {
            // Maybe the directory exists already
        }
        
        // Generate a unique Log ID
        let userName: String! = KeychainWrapper.defaultKeychainWrapper().stringForKey("LocNotes-username")!
        let userLoginToken: String! = KeychainWrapper.defaultKeychainWrapper().stringForKey("LocNotes-loginToken")!
        let currentTime: String = String(Int64(NSDate().timeIntervalSince1970))
        
        let uniqueLogID: String = CommonUtils.generateSHA512("\(userName)\(userLoginToken)\(currentTime)".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        // Check validity of user login token
        dispatch_barrier_async(uploadLocationLogQueue, {
            // Request for Login Token Renewal
            let tokenRenewalState: NSDictionary? = UserAuthentication.renewLoginToken()
            // Check if nil
            if( tokenRenewalState == nil ) {
                // Warn the user and cancel future
                self.cancelFuture = true
                // We failed to renew the login token, tell the user on the main thread
                dispatch_async(dispatch_get_main_queue(), {
                    // Remove the loading screen
                    self.loadingProgressView.removeFromSuperview()
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
                
                // Warn the user and cancel future
                self.cancelFuture = true
                // We failed to renew the login token, tell the user on the main thread
                dispatch_async(dispatch_get_main_queue(), {
                    // Remove the loading screen
                    self.loadingProgressView.removeFromSuperview()
                    // Tell the user where we hit a snag
                    CommonUtils.showDefaultAlertToUser(self, title: "Hit a Snag!", alertContents: "The server returned an invalid response while attempting to verify your login credentials. Please try again later!")
                })
                // Exit
                return
                
            } else if( tokenRenewalState!["status"] as! String == "renewed_but_failed" &&
                       tokenRenewalState!["reason"] as! String == "keychain_failed" ) {
                
                // Warn the user and cancel future
                self.cancelFuture = true
                // We failed to renew the login token, tell the user on the main thread
                dispatch_async(dispatch_get_main_queue(), {
                    // Remove the loading screen
                    self.loadingProgressView.removeFromSuperview()
                    // Tell the user where we hit a snag
                    CommonUtils.showDefaultAlertToUser(self, title: "Hit a Snag!", alertContents: "We failed to save your fresh login token into Keychain. Please try again later!")
                })
                // Exit
                return
                
            } else if( tokenRenewalState!["status"] as! String == "no_renewal" &&
                       tokenRenewalState!["reason"] as! String == "invalid_cred" ) {
                
                // Warn the user and cancel future
                self.cancelFuture = true
                // We failed to renew the login token, tell the user on the main thread
                dispatch_async(dispatch_get_main_queue(), {
                    // Remove the loading screen
                    self.loadingProgressView.removeFromSuperview()
                    // Tell the user where we hit a snag
                    CommonUtils.showDefaultAlertToUser(self, title: "Hit a Snag!", alertContents: "Your login credentials have expired. Please try logout and log back in to create new Location Logs.")
                })
                // Exit
                return
                
            } else if( ( tokenRenewalState!["status"] as! String == "no_renewal" && tokenRenewalState!["reason"] as! String == "not_needed" ) ||
                       ( tokenRenewalState!["status"] as! String == "renewed" && tokenRenewalState!["reason"] == nil ) ) {
                
                // Perfect, just proceed with the rest of the tasks
                
            }
        })
        
        // Spawn off the uploads to Amazon S3
        // CITATION: https://github.com/awslabs/aws-sdk-ios-samples/blob/master/S3TransferManager-Sample/Swift/S3TransferManagerSampleSwift/UploadViewController.swift
        for photoIndex in photoViews.indices {
            // Iterate over each of the photos and store temporarily in the app's directory
            dispatch_barrier_async(uploadLocationLogQueue, {
                
                // If the future tasks were cancelled, we must quit
                if( self.cancelFuture ) {
                    return
                }
                // See if we have a corresponding Amazon S3 Link and S3 ID with this photo view
                if( self.photoViews[photoIndex].amazonS3link != nil && !self.photoViews[photoIndex].amazonS3link!.isEmpty &&
                    self.photoViews[photoIndex].uniqueS3ID != nil && !self.photoViews[photoIndex].uniqueS3ID!.isEmpty ) {
                    return // We can skip uploading this image as we've got already got it down
                }
                
                // Now save the image to the temporary directory for the Amazon S3 Transfer Manager to pick up
                let fileName: String = NSProcessInfo.processInfo().globallyUniqueString.stringByAppendingString(".png")
                let fileURL: NSURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("amazons3upload").URLByAppendingPathComponent(fileName)
                let realImage: UIImage = CommonUtils.fetchUIImageFromPHAsset(self.photoViews[photoIndex].photoAsset)!
                
                let imageData: NSData? = UIImagePNGRepresentation(realImage)
                do {
                    _ = try Bool(imageData!.writeToFile(fileURL.path!, options: NSDataWritingOptions.DataWritingAtomic))
                } catch {
                    // Cancel future uploads
                    self.cancelFuture = true
                    // We failed to save the image, tell the user on the main thread
                    dispatch_async(dispatch_get_main_queue(), {
                        // Remove the loading screen
                        self.loadingProgressView.removeFromSuperview()
                        // Tell the user where we hit a snag
                        CommonUtils.showDefaultAlertToUser(self, title: "Hit a Snag!", alertContents: "We had issues saving the images to be uploaded. Please try again later!")
                    })
                    // Exit
                    return
                }
                
                // Generate a unique S3 Image ID
                let uniqueS3CurrentTime: String = String(Int64(NSDate().timeIntervalSince1970))
                let uniqueS3ID: String = CommonUtils.generateSHA512("\(userLoginToken)\(uniqueLogID)\(uniqueS3CurrentTime)".dataUsingEncoding(NSUTF8StringEncoding)!)
                
                // Resolve the destination S3 Bucket Name
                let awsUploadBucketName: String? = CommonUtils.fetchFromPropertiesList("amazon-aws-credentials", fileExtension: "plist", key: "s3bucketname")
                let awsUploadKey: String = "\(uniqueLogID)_\(uniqueS3ID)"
                // Spawn off the Amazon S3 Request now
                let amazonS3UploadRequest: AWSS3TransferManagerUploadRequest = AWSS3TransferManagerUploadRequest()
                amazonS3UploadRequest.body = fileURL
                amazonS3UploadRequest.key = awsUploadKey
                amazonS3UploadRequest.bucket = awsUploadBucketName
                
                // Send it to the Transfer Manager
                let amazonTransferManager: AWSS3TransferManager = AWSS3TransferManager.defaultS3TransferManager()
                let uploadTask: AWSTask = amazonTransferManager.upload(amazonS3UploadRequest)
                uploadTask.continueWithBlock{(task) -> AnyObject! in
                    if let _ = task.error {
                        
                        self.cancelFuture = true
                        // We failed to save the image, tell the user on the main thread
                        dispatch_async(dispatch_get_main_queue(), {
                            // Remove the loading screen
                            self.loadingProgressView.removeFromSuperview()
                            // Tell the user where we hit a snag
                            CommonUtils.showDefaultAlertToUser(self, title: "Hit a Snag!", alertContents: "We had issues saving the images to be uploaded. Please try again later!")
                        })
                        
                    } else if let _ = task.exception {
                        
                        self.cancelFuture = true
                        // We failed to save the image, tell the user on the main thread
                        dispatch_async(dispatch_get_main_queue(), {
                            // Remove the loading screen
                            self.loadingProgressView.removeFromSuperview()
                            // Tell the user where we hit a snag
                            CommonUtils.showDefaultAlertToUser(self, title: "Hit a Snag!", alertContents: "We had issues saving the images to be uploaded. Please try again later!")
                        })
                        
                    } else {
                        // Successful

                        // Update the UI Progress
                        dispatch_async(dispatch_get_main_queue(), {
                            self.loadingProgressView.loadingProgressBar.setProgress(Float(self.photoViews[photoIndex].photoViewIndex + 1) / Float((self.photoViews.count * 3) + 1), animated: true)
                            self.loadingProgressView.loadingProgressLabel.text = "Done uploading \(self.photoViews[photoIndex].photoViewIndex + 1) of \(self.photoViews.count) photos to Amazon S3"
                        })
                        // Also, fill in the PhotoViews array
                        self.photoViews[photoIndex].uniqueS3ID = uniqueS3ID
                        self.photoViews[photoIndex].amazonS3link = "https://s3.amazonaws.com/\(awsUploadBucketName!)/\(awsUploadKey).png"
                    }
                    // This is suppose to return nil
                    return nil
                }
                
                // Wait for it to end
                while( !uploadTask.completed ) {
                    // Sleep for one second
                    sleep(1)
                    // Now update the user with the progress of the upload
                    amazonS3UploadRequest.uploadProgress = {(bytesSent, totalBytesSent, totalBytesExpectedToSend) -> Void in
                        // Calculate the fresh progress
                        let progressToAddNum: Double = Double(totalBytesSent)
                        let progressToAddDenom: Double = Double(totalBytesExpectedToSend) * Double((self.photoViews.count * 3) + 1)
                        let progressToAdd: Float = Float(progressToAddNum / progressToAddDenom) + Float(self.photoViews[photoIndex].photoViewIndex)
                        let finalProgress: Float = Float(progressToAdd / Float((self.photoViews.count * 3) + 1))
                        // Update the UI
                        dispatch_async(dispatch_get_main_queue(), {
                            self.loadingProgressView.loadingProgressBar.setProgress(finalProgress, animated: true)
                        })
                    }
                }
            })
        }
        
        // Prepare for next step
        let awsEndpoint: String = CommonUtils.fetchFromPropertiesList("endpoints", fileExtension: "plist", key: "awsEC2EndpointURL")!
        let addS3ImageURL: String = CommonUtils.fetchFromPropertiesList("endpoints", fileExtension: "plist", key: "addS3imageURL")!
        let addLocationLogURL: String = CommonUtils.fetchFromPropertiesList("endpoints", fileExtension: "plist", key: "addLocationLogURL")!
        var s3IDs: [String] = []
        
        // Give a pause before we perform the next set of tasks
        if self.photoViews.count != 0 {
            // If we've got photos to process, then pause
            dispatch_barrier_async(uploadLocationLogQueue, {
                if self.cancelFuture {
                    return              // We are not suppose to be executing
                }
                // Sleep for two seconds
                sleep(2)
                // Tell the user about the new action
                dispatch_async(dispatch_get_main_queue(), {
                    self.loadingProgressView.loadingProgressLabel.text = "Preparing to upload S3 links to LocNotes backend..."
                })
                // Wait another two seconds
                sleep(2)
            })
        }
        
        // Now post the S3 links to the server
        for photoIndex in photoViews.indices {
            // Iterating over each of the PhotoViews now
            dispatch_barrier_async(uploadLocationLogQueue, {
                
                // If the future tasks were cancelled, we must quit
                if( self.cancelFuture ) {
                    return
                }
                
                // Add the current PhotoView's S3 ID to our list
                s3IDs.append(self.photoViews[photoIndex].uniqueS3ID!)
                
                // Now upload to our backend; Start the SYNC request
                let syncRequestURL: NSURL! = NSURL(string: "http://" + awsEndpoint + addS3ImageURL)
                let syncSession: NSURLSession! = NSURLSession.sharedSession()
                
                let syncRequest: NSMutableURLRequest! = NSMutableURLRequest(URL: syncRequestURL)
                syncRequest.HTTPMethod = "POST"
                syncRequest.cachePolicy = .ReloadIgnoringLocalCacheData
                syncRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                syncRequest.setValue(UserAuthentication.generateAuthorizationHeader(userName, userLoginToken: userLoginToken), forHTTPHeaderField: "Authorization")
                
                // Form LatLng String
                var latLng: String = ""
                if( self.photoViews[photoIndex].photoLocation != nil ) {
                    let latitude: String = NSNumber(double: (self.photoViews[photoIndex].photoLocation?.coordinate.latitude)! as Double).stringValue
                    let longitude: String = NSNumber(double: (self.photoViews[photoIndex].photoLocation?.coordinate.longitude)! as Double).stringValue
                    
                    latLng = "\(latitude),\(longitude)"
                }
                
                // Let us form a dictionary of <K, V> pairs to be sent
                // REFERENCE: http://stackoverflow.com/a/28009796/705471
                let requestParams: Dictionary<String, String>! = ["locationlogid": uniqueLogID,
                                                                  "imageurl": self.photoViews[photoIndex].amazonS3link!,
                                                                  "s3id": self.photoViews[photoIndex].uniqueS3ID!,
                                                                  "width": String(self.photoViews[photoIndex].photoAsset!.pixelWidth),
                                                                  "height": String(self.photoViews[photoIndex].photoAsset!.pixelHeight),
                                                                  "latlng": latLng]
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
                syncRequest.HTTPBody = requestBody.dataUsingEncoding(NSUTF8StringEncoding)
                
                // Create semaphore to give a feel of a Synchronous Request via an Async Handler xD
                // CITATION: http://stackoverflow.com/a/34308158/705471
                let semaphore = dispatch_semaphore_create(0)
                var syncResponse: (data: NSData?, response: NSURLResponse?, error: NSError?)? = nil
                
                let asyncTask = syncSession.dataTaskWithRequest(syncRequest, completionHandler: {(data: NSData?, response: NSURLResponse?, error: NSError?) -> () in
                    syncResponse = (data, response, error)
                    // Release the semaphore
                    dispatch_semaphore_signal(semaphore)
                })
                asyncTask.resume() // Start the task now
                
                // But wait for the request to finish and read the response
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                
                // Process the response as the request is done
                if( syncResponse?.error != nil ) {
                    // We've got an error; Cancel future tasks
                    self.cancelFuture = true
                    // Tell the user; and return
                    dispatch_async(dispatch_get_main_queue(), {
                        // Hide the loading view
                        self.loadingProgressView.removeFromSuperview()
                        // Also, alert the user
                        CommonUtils.showDefaultAlertToUser(self, title: "Hit a snag!", alertContents: "The server returned an invalid response. Please try again later!")
                    })
                    // Now, return
                    return
                }
                
                // If we've got a response, check it
                do {
                    
                    let jsonResponse: [String: AnyObject] = try (NSJSONSerialization.JSONObjectWithData(syncResponse!.data!, options: NSJSONReadingOptions()) as? [String: AnyObject])!
                    // Now process the response
                    let status = jsonResponse["status"]
                    
                    if( status == nil ) {
                        // We've got an error; Cancel future tasks
                        self.cancelFuture = true
                        // Warn the user
                        dispatch_async(dispatch_get_main_queue(), {
                            self.loadingProgressView.removeFromSuperview() // Hide the loading screen
                            // We've got some problems parsing the response; Show an alert to the user
                            CommonUtils.showDefaultAlertToUser(self, title: "Network Error", alertContents: "The server returned an invalid response. Please try again!")
                        })
                        // Return
                        return
                    }
                    
                    let strStatus: String! = status as! String
                    
                    if( strStatus == "success" ) {
                        
                        // Update the Progress View
                        dispatch_async(dispatch_get_main_queue(), {
                            self.loadingProgressView.loadingProgressBar.setProgress(Float(self.photoViews.count + (self.photoViews[photoIndex].photoViewIndex + 1)) / Float((self.photoViews.count * 3) + 1), animated: true)
                            self.loadingProgressView.loadingProgressLabel.text = "Done adding \(self.photoViews[photoIndex].photoViewIndex + 1) of \(self.photoViews.count) photos to LocNotes backend"
                        })
                        
                    } else if( strStatus == "failed" ) {
                        // Stop. We've gotta warn the user; Cancel future tasks
                        self.cancelFuture = true
                        // Warn the user
                        dispatch_async(dispatch_get_main_queue(), {
                            self.loadingProgressView.removeFromSuperview() // Hide the loading screen
                            // We've got some problems parsing the response; Show an alert to the user
                            CommonUtils.showDefaultAlertToUser(self, title: "Network Error", alertContents: "The server returned an invalid response. Please try to login again!")
                        })
                        // Return
                        return
                    } else if( strStatus == "unauthorized" ) {
                        // Stop. We've gotta warn the user; Cancel future tasks
                        self.cancelFuture = true
                        // Warn the user
                        dispatch_async(dispatch_get_main_queue(), {
                            self.loadingProgressView.removeFromSuperview() // Hide the loading screen
                            // We've got some problems parsing the response; Show an alert to the user
                            CommonUtils.showDefaultAlertToUser(self, title: "Network Error", alertContents: "The server claims that your login credentials are invalid. Please try again! If that doesn't resolve the issue, please re-login and then try adding your Location Log.")
                        })
                        // Return
                        return
                    }
                    
                } catch {
                    
                    // We've got an error; Cancel future tasks
                    self.cancelFuture = true
                    // Warn the user
                    dispatch_async(dispatch_get_main_queue(), {
                        self.loadingProgressView.removeFromSuperview() // Hide the loading screen
                        // We've got some problems parsing the response; Show an alert to the user
                        CommonUtils.showDefaultAlertToUser(self, title: "Network Error", alertContents: "The server returned an invalid response. Please try to login again!")
                    })
                    // Return
                    return
                    
                }
            })
        }
        
        // Give a pause before we perform the next set of tasks
        if self.photoViews.count != 0 {
            // If we've got photos to process, then pause
            dispatch_barrier_async(uploadLocationLogQueue, {
                if self.cancelFuture {
                    return              // We are not suppose to be executing
                }
                // Sleep for two seconds
                sleep(2)
                // Tell the user about the new action
                dispatch_async(dispatch_get_main_queue(), {
                    self.loadingProgressView.loadingProgressLabel.text = "Preparing to save your Location Log photos to local storage..."
                })
                // Wait another two seconds
                sleep(2)
            })
        }
        
        // Add the images to our CoreData set
        for photoIndex in photoViews.indices {
            // Iterating over each of the PhotoViews now
            dispatch_barrier_async(uploadLocationLogQueue, {
                
                // If the future tasks were cancelled, we must quit
                if( self.cancelFuture ) {
                    return
                }
                
                // CITATION:
                // http://stackoverflow.com/a/27996685/705471
                
                if self.managedContext == nil {
                    // We've got serious issues here; Warn the user
                    self.cancelFuture = true
                    // Warn the user
                    dispatch_async(dispatch_get_main_queue(), {
                        self.loadingProgressView.removeFromSuperview() // Hide the loading screen
                        // We've got some problems parsing the response; Show an alert to the user
                        CommonUtils.showDefaultAlertToUser(self, title: "System Error", alertContents: "CoreData API failed to save objects. Please try again later!")
                    })
                    // And return:
                    return
                }
                
                guard let fullResolutionS3Image: FullResolutionS3Image = NSEntityDescription.insertNewObjectForEntityForName("FullResolutionS3Image", inManagedObjectContext: self.managedContext!) as? FullResolutionS3Image, let imageThumbnail: ImageThumbnail = NSEntityDescription.insertNewObjectForEntityForName("ImageThumbnail", inManagedObjectContext: self.managedContext!) as? ImageThumbnail else
                {
                    self.cancelFuture = true
                    // Warn the user
                    dispatch_async(dispatch_get_main_queue(), {
                        self.loadingProgressView.removeFromSuperview() // Hide the loading screen
                        // We've got some problems parsing the response; Show an alert to the user
                        CommonUtils.showDefaultAlertToUser(self, title: "System Error", alertContents: "CoreData API failed to save objects. Please try again later!")
                    })
                    // And return:
                    return
                }
                
                // Fill out the information
                fullResolutionS3Image.amazonS3link = self.photoViews[photoIndex].amazonS3link
                fullResolutionS3Image.image = UIImagePNGRepresentation(CommonUtils.fetchUIImageFromPHAsset(self.photoViews[photoIndex].photoAsset)!)
                fullResolutionS3Image.s3id = self.photoViews[photoIndex].uniqueS3ID
                fullResolutionS3Image.storeDate = NSNumber(longLong: Int64(NSDate().timeIntervalSince1970))
                
                imageThumbnail.fullResS3id = self.photoViews[photoIndex].uniqueS3ID
                imageThumbnail.image = UIImagePNGRepresentation(self.photoViews[photoIndex].thumbnailImage!)
                
                // Save the new objects
                do {
                    try self.managedContext?.save()
                } catch {
                    self.cancelFuture = true
                    // Warn the user
                    dispatch_async(dispatch_get_main_queue(), {
                        self.loadingProgressView.removeFromSuperview() // Hide the loading screen
                        // We've got some problems parsing the response; Show an alert to the user
                        CommonUtils.showDefaultAlertToUser(self, title: "System Error", alertContents: "CoreData API failed to save objects. Please try again later!")
                    })
                    // And return:
                    return
                }
                
                // Clear to free up memory
                self.managedContext?.refreshAllObjects()
                
                // Update the UI; Update the Progress View
                dispatch_async(dispatch_get_main_queue(), {
                    self.loadingProgressView.loadingProgressBar.setProgress(Float((2 * self.photoViews.count) + (self.photoViews[photoIndex].photoViewIndex + 1)) / Float((self.photoViews.count * 3) + 1), animated: true)
                    self.loadingProgressView.loadingProgressLabel.text = "Done adding \(self.photoViews[photoIndex].photoViewIndex + 1) of \(self.photoViews.count) photos to local storage"
                })
                
            })
        }
        
        // Give a pause before we perform the next set of tasks
        if self.photoViews.count != 0 {
            // If we've got photos to process, then pause
            dispatch_barrier_async(uploadLocationLogQueue, {
                if self.cancelFuture {
                    return              // We are not suppose to be executing
                }
                // Sleep for two seconds
                sleep(2)
                // Tell the user about the new action
                dispatch_async(dispatch_get_main_queue(), {
                    self.loadingProgressView.loadingProgressLabel.text = "Compiling all the information for the LocNotes backend..."
                })
                // Wait another two seconds
                sleep(2)
            })
        }
        
        // Finally, upload it to the LocNotes Backend
        dispatch_barrier_async(uploadLocationLogQueue, {
            
            // If the future tasks were cancelled, we must quit
            if( self.cancelFuture ) {
                return
            }
            
            // Compile the S3 IDs
            var s3AddedFirst: Bool = false
            var s3IDsCompiled: String = ""
            s3IDs = ["a","b","c"]
            
            for s3id in s3IDs {
                if s3AddedFirst {
                    s3IDsCompiled = s3IDsCompiled + ";" + s3id      // Add delimiter and then the next item
                } else {
                    s3AddedFirst = true     // Toggle that
                    s3IDsCompiled = s3id    // Add the first item to the list
                }
            }
            
            // Compile Location Names and Location Points
            var locNameAddedFirst: Bool = false
            var locNameListCompiled: String = ""
            var locPointsListCompiled: String = ""
            
            for location in self.locationsUserVisited {
                if locNameAddedFirst {
                    locNameListCompiled = locNameListCompiled + ";;;" + location.placemark.title!       // Add delimiter and then the next item
                    locPointsListCompiled = locPointsListCompiled + ";" + "\(location.placemark.coordinate.latitude),\(location.placemark.coordinate.longitude)"    // Add the next location coord after the delimiter
                } else {
                    locNameAddedFirst = true    // Toggle that
                    locNameListCompiled = location.placemark.title!     // Add the first location name
                    locPointsListCompiled = "\(location.placemark.coordinate.latitude),\(location.placemark.coordinate.longitude)"      // Add the first location coord
                }
            }
            
            // Make a synchronous request to the LocNotes EC2 backend
            let syncRequestURL: NSURL! = NSURL(string: "http://" + awsEndpoint + addLocationLogURL)
            let syncSession: NSURLSession! = NSURLSession.sharedSession()
            
            let requestParams: Dictionary<String, String>! = ["locationlogid": uniqueLogID,
                                                              "title": self.titleTextField.text!,
                                                              "desc": self.descriptionTextField.text!,
                                                              "s3ids": s3IDsCompiled,
                                                              "locnames": locNameListCompiled,
                                                              "locpoints": locPointsListCompiled]
            // Form the request with these parameters
            let syncRequest: NSMutableURLRequest! = MultipartFormDataHTTP().createRequest(syncRequestURL, param: requestParams)
            syncRequest.setValue(UserAuthentication.generateAuthorizationHeader(userName, userLoginToken: userLoginToken), forHTTPHeaderField: "Authorization")
            
            // Create semaphore to give a feel of a Synchronous Request via an Async Handler xD
            // CITATION: http://stackoverflow.com/a/34308158/705471
            let semaphore = dispatch_semaphore_create(0)
            var syncResponse: (data: NSData?, response: NSURLResponse?, error: NSError?)? = nil
            
            let asyncTask = syncSession.dataTaskWithRequest(syncRequest, completionHandler: {(data: NSData?, response: NSURLResponse?, error: NSError?) -> () in
                syncResponse = (data, response, error)
                // Release the semaphore
                dispatch_semaphore_signal(semaphore)
            })
            asyncTask.resume() // Start the task now
            
            // But wait for the request to finish and read the response
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            
            // Process the response now
            if( syncResponse?.error != nil ) {
                // We've got a problem
                self.cancelFuture = true
                // Tell the user; and return
                dispatch_async(dispatch_get_main_queue(), {
                    // Hide the loading view
                    self.loadingProgressView.removeFromSuperview()
                    // Also, alert the user
                    CommonUtils.showDefaultAlertToUser(self, title: "Hit a snag!", alertContents: "We got an invalid response from the server. Please try again later!")
                })
                // Exit the function now
                return
            }
            
            // Now process the response as we've got no errors
            do {
                
                let jsonResponse: [String: AnyObject] = try (NSJSONSerialization.JSONObjectWithData(syncResponse!.data!, options: NSJSONReadingOptions()) as? [String: AnyObject])!
                // Now process the response
                let status = jsonResponse["status"]
                
                if( status == nil ) {
                    // We've got an error; Cancel future tasks
                    self.cancelFuture = true
                    // Warn the user
                    dispatch_async(dispatch_get_main_queue(), {
                        self.loadingProgressView.removeFromSuperview() // Hide the loading screen
                        // We've got some problems parsing the response; Show an alert to the user
                        CommonUtils.showDefaultAlertToUser(self, title: "Network Error", alertContents: "The server returned an invalid response. Please try again!")
                    })
                    // Return
                    return
                }
                
                let strStatus: String! = status as! String
                
                if( strStatus == "success" ) {
                    
                    // Update the Progress View
                    dispatch_async(dispatch_get_main_queue(), {
                        self.loadingProgressView.loadingProgressLabel.text = "Updated the LocNotes backend"
                    })
                    // Get the Added Date
                    let addedTime: Double! = (jsonResponse["token_expiry"] as? NSNumber)?.doubleValue
                    
                    // Now save it in CoreData
                    if self.managedContext == nil {
                        // We've got serious issues here; Warn the user
                        self.cancelFuture = true
                        // Warn the user
                        dispatch_async(dispatch_get_main_queue(), {
                            self.loadingProgressView.removeFromSuperview() // Hide the loading screen
                            // We've got some problems parsing the response; Show an alert to the user
                            CommonUtils.showDefaultAlertToUser(self, title: "System Error", alertContents: "CoreData API failed to save objects. Please try again later!")
                        })
                        // And return:
                        return
                    }
                    
                    guard let locationLog: LocationLog = NSEntityDescription.insertNewObjectForEntityForName("LocationLog", inManagedObjectContext: self.managedContext!) as? LocationLog else
                    {
                        self.cancelFuture = true
                        // Warn the user
                        dispatch_async(dispatch_get_main_queue(), {
                            self.loadingProgressView.removeFromSuperview() // Hide the loading screen
                            // We've got some problems parsing the response; Show an alert to the user
                            CommonUtils.showDefaultAlertToUser(self, title: "System Error", alertContents: "CoreData API failed to save objects. Please try again later!")
                        })
                        // And return:
                        return
                    }
                    
                    // Fill out the information
                    locationLog.addedDate = addedTime
                    locationLog.imageS3ids = s3IDsCompiled
                    locationLog.locationNames = locNameListCompiled
                    locationLog.logDesc = self.descriptionTextField.text!
                    locationLog.logID = uniqueLogID
                    locationLog.logTitle = self.titleTextField.text!
                    locationLog.updateDate = addedTime
                    
                    // Attempt to save it now
                    do {
                        try self.managedContext?.save()
                    } catch {
                        self.cancelFuture = true
                        // Warn the user
                        dispatch_async(dispatch_get_main_queue(), {
                            self.loadingProgressView.removeFromSuperview() // Hide the loading screen
                            // We've got some problems parsing the response; Show an alert to the user
                            CommonUtils.showDefaultAlertToUser(self, title: "System Error", alertContents: "CoreData API failed to save objects. Please try again later!")
                        })
                        // And return:
                        return
                    }
                    
                    // Clear to free up memory
                    self.managedContext?.refreshAllObjects()
                    
                    // Update the UI; Update the Progress View
                    dispatch_async(dispatch_get_main_queue(), {
                        self.loadingProgressView.loadingProgressBar.setProgress(1, animated: true)
                        self.loadingProgressView.loadingProgressLabel.text = "Done saving your location log"
                        self.loadingProgressView.loadingProgressIndicator.hidden = true
                    })
                    
                } else if( strStatus == "failed" ) {
                    // Stop. We've gotta warn the user; Cancel future tasks
                    self.cancelFuture = true
                    // Warn the user
                    dispatch_async(dispatch_get_main_queue(), {
                        self.loadingProgressView.removeFromSuperview() // Hide the loading screen
                        // We've got some problems parsing the response; Show an alert to the user
                        CommonUtils.showDefaultAlertToUser(self, title: "Network Error", alertContents: "The server returned an invalid response. Please try to login again!")
                    })
                    // Return
                    return
                } else if( strStatus == "unauthorized" ) {
                    // Stop. We've gotta warn the user; Cancel future tasks
                    self.cancelFuture = true
                    // Warn the user
                    dispatch_async(dispatch_get_main_queue(), {
                        self.loadingProgressView.removeFromSuperview() // Hide the loading screen
                        // We've got some problems parsing the response; Show an alert to the user
                        CommonUtils.showDefaultAlertToUser(self, title: "Network Error", alertContents: "The server claims that your login credentials are invalid. Please try again! If that doesn't resolve the issue, please re-login and then try adding your Location Log.")
                    })
                    // Return
                    return
                }
                
            } catch {
                
                // We've got an error; Cancel future tasks
                self.cancelFuture = true
                // Warn the user
                dispatch_async(dispatch_get_main_queue(), {
                    self.loadingProgressView.removeFromSuperview() // Hide the loading screen
                    // We've got some problems parsing the response; Show an alert to the user
                    CommonUtils.showDefaultAlertToUser(self, title: "Network Error", alertContents: "The server returned an invalid response. Please try to login again!")
                })
                // Return
                return
                
            }
        })
        
        // Andddd, we're done
        // Finally, tell the user and take him back to the list of Location Logs screen
        // Be sure to have that view refreshed
        // TODO
        
    }
    
    // MARK: - Validation Tests
    func locationLogSubmissionValidationTests() -> Bool {
        // Check the title
        if( self.titleTextField.text?.isEmpty == true ) {
            // Tell the user and return
            CommonUtils.showDefaultAlertToUser(self, title: "Validation Error", alertContents: "You cannot have an empty title for a Location Log. Please enter a title to proceed saving your Location Log!")
            // Return
            return false
        }
        
        // Check for the description
        if( self.descriptionTextField.text?.isEmpty == true || self.descriptionTextField.text == self.defaultDescriptionTextFieldPlaceholder ) {
            // Tell the user and return
            CommonUtils.showDefaultAlertToUser(self, title: "Validation Error", alertContents: "You cannot have an empty description for a Location Log. Please enter a description to proceed saving your Location Log!")
            // Return
            return false
        }
        
        // Else, return true
        return true
    }
    
    // MARK: - Segue actions handler here
    @IBAction func unwindSegue(segue: UIStoryboardSegue) {
        if( segue.sourceViewController.isKindOfClass(AddLocationToLocationLogViewController) ) {
            // Extract the locations confirmed by the user
            let sourceVC: AddLocationToLocationLogViewController = segue.sourceViewController as! AddLocationToLocationLogViewController
            // Iterate over each of the MapItems the user chose and add it to our list and force the Locations Visited Table to refresh
            for mapItem in sourceVC.confirmedMapItems {
                self.locationsUserVisited.append(mapItem)
            }
            self.locationVisitedTable.reloadData()
        }
    }
    
    // MARK: - Other methods
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews() // Let the super do its stuff
        logPhotosCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: - Orientation Change Listener
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()           // Let the super do its stuff
        // Re-setup the views
        setupView()
    }

}