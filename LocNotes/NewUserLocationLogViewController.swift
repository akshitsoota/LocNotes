//
//  NewUserLocationLogViewController.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/7/16.
//  Copyright © 2016 axe. All rights reserved.
//

import Photos
import UIKit

class NewUserLocationLogViewController: UIViewController, UITextViewDelegate, UICollectionViewDataSource,
                                        UINavigationControllerDelegate, UIImagePickerControllerDelegate,
                                        UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource
{

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
    var locationsUserVisited: [String] = []
    // Holds what action is happening in Locations Visited Table
    var locationsVisitedTableAction: Int = -1 // -1 = Nothing; 0 = Multi-Remove; 1 = Re-order mode
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup view
        setupView()
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
    }
    
    // MARK: - TextView Delegate functions to deal with placeholder text
    func textViewDidBeginEditing(textView: UITextView) {
        if( textView == descriptionTextField &&
            textView.textColor == defaultDescriptionTextFieldPlaceholderColor ) {
            
            textView.text = nil
            textView.textColor = UIColor.blackColor()
        }
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if( textView == descriptionTextField &&
            textView.text.isEmpty ) {
            
            textView.text = defaultDescriptionTextFieldPlaceholder
            textView.textColor = defaultDescriptionTextFieldPlaceholderColor
        }
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
        cell.textLabel?.text = self.locationsUserVisited[indexPath.row]
        
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
        let objectMoved: String = self.locationsUserVisited[sourceIndexPath.row]
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
    // MARK: - Segue actions handler here
    @IBAction func unwindSegue(segue: UIStoryboardSegue) {
        if( segue.sourceViewController.isKindOfClass(AddLocationToLocationLogViewController) ) {
            // Extract the locations confirmed by the user
            let sourceVC: AddLocationToLocationLogViewController = segue.sourceViewController as! AddLocationToLocationLogViewController
            // Iterate over each of the MapItems the user chose and add it to our list and force the Locations Visited Table to refresh
            for mapItem in sourceVC.confirmedMapItems {
                self.locationsUserVisited.append(mapItem.placemark.title!)
            }
            self.locationVisitedTable.reloadData()
        }
    }
    
    // MARK: - Other methods
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews() // Let the super do its stuff
        logPhotosCollectionView.collectionViewLayout.invalidateLayout()
    }

}
