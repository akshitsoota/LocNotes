//
//  UserLocationLogsViewController.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/6/16.
//  Copyright © 2016 axe. All rights reserved.
//

import AWSCore
import AWSS3

import CoreData
import UIKit

class UserLocationLogsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var locationLogsTableView: UITableView!
    let reuseIdentifierlocationLogWithImage: String = "locationLogCellWithImage"
    let reuseIdentifierlocationLogWithoutImage: String = "locationLogCellWithoutImage"
    // Holds the Refresh Button Navigation Bar Item
    var navigationItemRefreshButton: UIBarButtonItem?
    // Array that holds all the Location Logs fetched from Core Data
    var locationLogs: [LocationLog] = []
    // Dictionary to hold the images for each Location Log that has images associated with them
    var locationLogImages: Dictionary<String, UIImage> = [String: UIImage]()
    // Holds if the TableView should show a loading cell or not
    var tableViewLoadingCellShown: Bool = false
    // Holds the TableView Progress information
    var tableViewLoadingCellProgressText: String = ""
    var tableViewLoadingCellProgressValue: Float = 0
    // Holds if the ViewController wants our LocationLogs to be auto-refreshed
    var autoRefreshLocationLogsOnLoad: Bool = false
    // Holds the loading screen that would be shown on the screen
    var loadingScreen: UIView?
    
    // Dispatch Queues
    let refreshLogQueue = dispatch_queue_create("RefreshLocationLogQueue", DISPATCH_QUEUE_CONCURRENT)
    // Core Data Managed Context
    var managedContext : NSManagedObjectContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Fetch Location logs from CoreData
        fetchLocationLogs()
        // Set up the views
        setupViews()
        // Check if we should implictly refresh
        if( self.autoRefreshLocationLogsOnLoad ) {
            forceAutoRefreshLocationLogs()
        }
        // Enable swipe to Go Back for this UINavigationController
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
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
    
    // MARK: - Setup View Functions here
    func fetchLocationLogs() {
        func resizeImage(image: UIImage, size: CGSize) -> UIImage {
            // CITATION: http://stackoverflow.com/a/7775470/705471
            
            let newRect: CGRect = CGRectIntegral(CGRectMake(0, 0, size.width, size.height))
            let imageRef: CGImageRef = image.CGImage!
            
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            let context = UIGraphicsGetCurrentContext()
            
            CGContextSetInterpolationQuality(context, CGInterpolationQuality.High)
            let flipVertical: CGAffineTransform = CGAffineTransformMake(1, 0, 0, -1, 0, size.height)
            
            CGContextConcatCTM(context, flipVertical)
            CGContextDrawImage(context, newRect, imageRef)
            
            let newImageRef: CGImageRef = CGBitmapContextCreateImage(context)! as CGImage
            let newImage: UIImage = UIImage(CGImage: newImageRef)
            
            UIGraphicsEndImageContext()
            
            return newImage
        }
        
        // Load the Managed Context from the AppDelegate
        if( self.managedContext == nil ) {
            self.managedContext = AppDelegate().managedObjectContext
        }
        // Proceed to querying it
        let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "LocationLog")
        let imageFetchQuery: NSFetchRequest = NSFetchRequest(entityName: "FullResolutionS3Image")
        do {
            let results = try self.managedContext?.executeFetchRequest(fetchRequest)
            let locationLogs: [LocationLog] = results as! [LocationLog]
            
            let imageResults = try self.managedContext?.executeFetchRequest(imageFetchQuery)
            let images: [FullResolutionS3Image] = imageResults as! [FullResolutionS3Image]
            
            // Save the Location Logs reversed
            self.locationLogs = locationLogs.sort({(first: LocationLog, second: LocationLog) -> Bool in
                return Double(first.addedDate!) > Double(second.addedDate!)
            })
            
            // Update the Image Array for the location logs
            self.locationLogImages = [String: UIImage]()
            // Iterate over each of the Location Logs
            for locationLog in self.locationLogs {
                // Check if this posses an image or not
                if( locationLog.imageS3ids != nil && locationLog.imageS3ids?.isEmpty == false ) {
                    // There is an image here
                    let firstS3ImageID: String = (locationLog.imageS3ids?.characters.split(";").map(String.init)[0])!
                    // Find the image here
                    for anImage in images {
                        if( anImage.respectiveLogID == locationLog.logID && anImage.s3id == firstS3ImageID ) {
                            self.locationLogImages[locationLog.logID!] = resizeImage(UIImage(data: anImage.image!)!, size: CGSizeMake(UIScreen.mainScreen().bounds.width, 250))
                            // We found the image and we saved it, so:
                            break
                        }
                    }
                    // Done!
                }
            }
            
        } catch {
            CommonUtils.showDefaultAlertToUser(self, title: "CoreData Error", alertContents: "We were unable to pull your Location Logs using the CoreData API. Please re-open the application to try again!")
        }
    }
    
    func setupViews() {
        // Table View Delegate should be us
        self.locationLogsTableView.delegate = self
        // Also the Data Source
        self.locationLogsTableView.dataSource = self
        
        // Setup Table View No Location Logs Background
        let nibArray: [AnyObject] = NSBundle.mainBundle().loadNibNamed("NoLocationLogsView", owner: self, options: nil)
        let toReturn = nibArray[0] as! UIView
        toReturn.frame.size = self.locationLogsTableView.frame.size
        self.locationLogsTableView.backgroundView = toReturn
        
        // Grab the refresh button reference
        self.navigationItemRefreshButton = self.navigationItem.leftBarButtonItem
        
        // Configure TableView for appropriate editing
        self.locationLogsTableView.allowsMultipleSelectionDuringEditing = false
    }
    
    func forceAutoRefreshLocationLogs() {
        self.navigationBarRefreshButtonClicked(self)
    }
    
    // MARK: - UITableView Delegate and Data Source Functions
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // See if the "No Location Logs" view has to be shown or not
        if( locationLogs.count == 0 ) {
            self.locationLogsTableView.separatorStyle = .None
            self.locationLogsTableView.backgroundView?.hidden = false
        } else {
            self.locationLogsTableView.separatorStyle = .SingleLine
            self.locationLogsTableView.backgroundView?.hidden = true
        }
        // Now return
        if( self.tableViewLoadingCellShown ) {
            return locationLogs.count + 1
        }
        return locationLogs.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Check if we are loading something
        if( self.tableViewLoadingCellShown && indexPath.row == 0 ) {
            // Return the loading cell
            let origTableCell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("progressLocationLogCell")!
            let progressCell: ProgressLocationLogTableViewCell = origTableCell as! ProgressLocationLogTableViewCell
            // Now set the information
            progressCell.informationText.text = self.tableViewLoadingCellProgressText
            progressCell.progressBar.setProgress(self.tableViewLoadingCellProgressValue, animated: true)
            // Set TableViewCell Insets
            progressCell.preservesSuperviewLayoutMargins = false
            progressCell.separatorInset = UIEdgeInsetsZero
            progressCell.layoutMargins = UIEdgeInsetsZero
            
            // Now, return
            return progressCell
        }
        // Now, fetch the TableViewCell accordingly
        var llIndex: Int = indexPath.row
        
        if( self.tableViewLoadingCellShown ) {
            llIndex -= 1      // The first cell is the Loading Cell
        }
        
        if( self.locationLogs[llIndex].imageS3ids == nil || self.locationLogs[llIndex].imageS3ids?.isEmpty == true ) {
            // We've got no images
            let origTableCell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifierlocationLogWithoutImage)!
            let locationLogCell: LocationLogWithoutImageTableViewCell = origTableCell as! LocationLogWithoutImageTableViewCell
            // Now, set the information
            locationLogCell.locationLogTitle.text = self.locationLogs[llIndex].logTitle!
            locationLogCell.locationLogDesc.text = self.locationLogs[llIndex].logDesc!
            // Set TableViewCell Insets
            locationLogCell.preservesSuperviewLayoutMargins = false
            locationLogCell.separatorInset = UIEdgeInsetsZero
            locationLogCell.layoutMargins = UIEdgeInsetsZero
            
            // Now, return
            return locationLogCell
        } else {
            // We've got images
            let origTableCell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifierlocationLogWithImage)!
            let locationLogCell: LocationLogWithImageTableViewCell = origTableCell as! LocationLogWithImageTableViewCell
            // Now, set the information
            locationLogCell.locationLogTitle.text = self.locationLogs[llIndex].logTitle!
            locationLogCell.locationLogDesc.text = self.locationLogs[llIndex].logDesc!
            locationLogCell.imageHolder.image = self.locationLogImages[self.locationLogs[llIndex].logID!]
            // Set TableViewCell Insets
            locationLogCell.preservesSuperviewLayoutMargins = false
            locationLogCell.separatorInset = UIEdgeInsetsZero
            locationLogCell.layoutMargins = UIEdgeInsetsZero
            
            // Now, return
            return locationLogCell
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // Check if we are loading something
        if( self.tableViewLoadingCellShown && indexPath.row == 0 ) {
            return 64
        }
        // Else, check:
        var llIndex: Int = indexPath.row
        
        if( self.tableViewLoadingCellShown ) {
            llIndex -= 1      // The first cell is the Loading Cell
        }
        
        if( self.locationLogs[llIndex].imageS3ids == nil || self.locationLogs[llIndex].imageS3ids?.isEmpty == true ) {
            // No images cell => 64
            return 64
        } else {
            return 250
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if( editingStyle == .Delete ) {
            // We are only supporting this Editing Style
            
            // Ask the user for confirmation
            let actionSheet: UIAlertController = UIAlertController(title: nil, message: "Are you sure you want to delete this Location Log? This action cannot be undone", preferredStyle: .ActionSheet)
            let deleteAction: UIAlertAction = UIAlertAction(title: "Delete", style: .Destructive, handler: {(alert: UIAlertAction) -> Void in
                // Show up a loading screen
                if( self.loadingScreen == nil ) {
                    self.loadingScreen = CommonUtils.returnLoadingScreenView(self, size: UIScreen.mainScreen().bounds)
                }
                CommonUtils.setLoadingTextOnLoadingScreenView(self.loadingScreen, newLabelContents: "Deleting your location log...")
                self.navigationController?.view.addSubview(self.loadingScreen!)
                
                // Check the Login Token Validity
                let tokenRenewalState: NSDictionary? = UserAuthentication.renewLoginToken()
                // Check if nil
                if( tokenRenewalState == nil ) {
                    // We failed to renew the login token, tell the user on the main thread
                    dispatch_async(dispatch_get_main_queue(), {
                        // Hide the loading screen
                        self.loadingScreen!.removeFromSuperview()
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
                        self.loadingScreen!.removeFromSuperview()
                        // Tell the user where we hit a snag
                        CommonUtils.showDefaultAlertToUser(self, title: "Hit a Snag!", alertContents: "The server returned an invalid response while attempting to verify your login credentials. Please try again later!")
                    })
                    // Exit
                    return
                    
                } else if( tokenRenewalState!["status"] as! String == "renewed_but_failed" && tokenRenewalState!["reason"] as! String == "keychain_failed" ) {
                    
                    // We failed to renew the login token, tell the user on the main thread
                    dispatch_async(dispatch_get_main_queue(), {
                        // Hide the loading screen
                        self.loadingScreen!.removeFromSuperview()
                        // Tell the user where we hit a snag
                        CommonUtils.showDefaultAlertToUser(self, title: "Hit a Snag!", alertContents: "We failed to save your fresh login token into Keychain. Please try again later!")
                    })
                    // Exit
                    return
                    
                } else if( tokenRenewalState!["status"] as! String == "no_renewal" && tokenRenewalState!["reason"] as! String == "invalid_cred" ) {
                    
                    // We failed to renew the login token, tell the user on the main thread
                    dispatch_async(dispatch_get_main_queue(), {
                        // Hide the loading screen
                        self.loadingScreen!.removeFromSuperview()
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
                let deleteLocationLogsURL: String = CommonUtils.fetchFromPropertiesList("endpoints", fileExtension: "plist", key: "deleteLocationLogURL")!
                
                let userName: String! = KeychainWrapper.defaultKeychainWrapper().stringForKey("LocNotes-username")!
                let userLoginToken: String! = KeychainWrapper.defaultKeychainWrapper().stringForKey("LocNotes-loginToken")!
                
                // Now start the async request
                let asyncRequestURL: NSURL! = NSURL(string: "http://" + awsEndpoint + deleteLocationLogsURL)
                let asyncSession: NSURLSession! = NSURLSession.sharedSession()
                
                let asyncRequest: NSMutableURLRequest! = NSMutableURLRequest(URL: asyncRequestURL)
                asyncRequest.HTTPMethod = "POST"
                asyncRequest.cachePolicy = .ReloadIgnoringLocalCacheData
                asyncRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                asyncRequest.setValue(UserAuthentication.generateAuthorizationHeader(userName, userLoginToken: userLoginToken), forHTTPHeaderField: "Authorization")
                
                // Setup the POST Body to send the Location Log ID to be delete
                var requestBody = "locationlogid=" + self.locationLogs[indexPath.row].logID!
                
                requestBody = requestBody.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
                asyncRequest.HTTPBody = requestBody.dataUsingEncoding(NSUTF8StringEncoding)
                
                // Now start the Async task
                let asyncTask = asyncSession.dataTaskWithRequest(asyncRequest, completionHandler: {(data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                    // Check for any errors
                    if( error != nil ) {
                        // Tell the user that we failed to log them out
                        dispatch_async(dispatch_get_main_queue(), {
                            // Hide the loading screen
                            self.loadingScreen!.removeFromSuperview()
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
                                self.loadingScreen!.removeFromSuperview()
                                // Alert the user
                                CommonUtils.showDefaultAlertToUser(self, title: "Server Error", alertContents: "We received an invalid response from the server. Please try again later!")
                            })
                            // Return
                            return
                        }
                        
                        let strStatus: String! = status as! String
                        
                        if( strStatus == "success" ) {
                            
                            // Clear up CoreData to remove this Location Log
                            
                            var s3IDsToDelete: [String] = [] // Also collect the S3 IDs to be deleted
                            
                            // Search of the Location Log that has to be delete
                            let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "LocationLog")
                            do {
                                let results = try self.managedContext?.executeFetchRequest(fetchRequest)
                                let locationLogs: [LocationLog] = results as! [LocationLog]
                                
                                // Iterate over them and see which one should be delete
                                for locationLog in locationLogs {
                                    if locationLog.logID == self.locationLogs[indexPath.row].logID! {
                                        // Save all the S3 IDs to be deleted
                                        if( locationLog.imageS3ids != nil && !(locationLog.imageS3ids?.isEmpty)! ) {
                                            for s3id in (locationLog.imageS3ids?.componentsSeparatedByString(";"))! {
                                                s3IDsToDelete.append("\(s3id)")
                                            }
                                        }
                                        // Ask CoreData to delete
                                        self.managedContext?.deleteObject(locationLog)
                                        // Ask Context To Save It
                                        try self.managedContext?.save()
                                        // We found it so:
                                        break
                                    }
                                }
                            } catch {  }
                            
                            if( s3IDsToDelete.count != 0 ) {
                                // We've got S3 Image to delete from user's CoreData for this specific Location Log
                                
                                let imagesFetchRequest: NSFetchRequest = NSFetchRequest(entityName: "FullResolutionS3Image")
                                do {
                                    let imageResults = try self.managedContext?.executeFetchRequest(imagesFetchRequest)
                                    let images: [FullResolutionS3Image] = imageResults as! [FullResolutionS3Image]
                                    
                                    // Iterate over them and see which one to delete
                                    for image in images {
                                        if image.respectiveLogID! == self.locationLogs[indexPath.row].logID! &&
                                           s3IDsToDelete.contains("\(image.s3id!)") {
                                            // Remove this image
                                            self.managedContext?.deleteObject(image)
                                            // Ask Context to save the changes
                                            try self.managedContext?.save()
                                        }
                                    }
                                } catch {  }
                                
                                let thumbnailFetchRequest: NSFetchRequest = NSFetchRequest(entityName: "ImageThumbnail")
                                do {
                                    let thumbnailResults = try self.managedContext?.executeFetchRequest(thumbnailFetchRequest)
                                    let thumbnails: [ImageThumbnail] = thumbnailResults as! [ImageThumbnail]
                                    
                                    // Iterate over them and see which ones to delete
                                    for thumbnail in thumbnails {
                                        if thumbnail.respectiveLogID! == self.locationLogs[indexPath.row].logID! &&
                                           s3IDsToDelete.contains("\(thumbnail.fullResS3id!)") {
                                            // Remove this thumbnail
                                            self.managedContext?.deleteObject(thumbnail)
                                            // Ask Context to save changes
                                            try self.managedContext?.save()
                                        }
                                    }
                                } catch {  }
                                
                            }
                            
                            // Take the user to the login screen
                            dispatch_async(dispatch_get_main_queue(), {
                                self.loadingScreen!.removeFromSuperview()
                                // Force a reload from CoreData
                                self.fetchLocationLogs()
                                // Force an update of the TableView
                                self.locationLogsTableView.beginUpdates()
                                self.locationLogsTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
                                self.locationLogsTableView.endUpdates()
                            })
                            // And we're done
                            return
                            
                        }
                        
                    } catch {
                        // Tell the user that we couldn't log them out
                        dispatch_async(dispatch_get_main_queue(), {
                            // Hide the loading screen
                            self.loadingScreen!.removeFromSuperview()
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
    
    @IBAction func navigationBarRefreshButtonClicked(sender: AnyObject) {
        // TODO: Check for Wi-Fi
        
        // Force an update of the list from CoreData
        self.fetchLocationLogs()
        
        // Show the activity indicator instead of the Refresh Button
        let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView.init(activityIndicatorStyle: .White)
        let refreshBarButton: UIBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        self.navigationItem.leftBarButtonItem = refreshBarButton
        activityIndicator.startAnimating()
        // Show activity indicator on the Status Bar
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        // Spawn off the request on another thread
        dispatch_barrier_async(self.refreshLogQueue, {
            // Ensure we've got a valid Login Token
            // Request for Login Token Renewal
            let tokenRenewalState: NSDictionary? = UserAuthentication.renewLoginToken()
            // Check if nil
            if( tokenRenewalState == nil ) {
                // We failed to renew the login token, tell the user on the main thread
                dispatch_async(dispatch_get_main_queue(), {
                    // Remove the activity indicator from the navigation bar
                    self.navigationItem.leftBarButtonItem = self.navigationItemRefreshButton
                    // Hide activity indicator on the Status Bar
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
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
                    // Remove the activity indicator from the navigation bar
                    self.navigationItem.leftBarButtonItem = self.navigationItemRefreshButton
                    // Hide activity indicator on the Status Bar
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    // Tell the user where we hit a snag
                    CommonUtils.showDefaultAlertToUser(self, title: "Hit a Snag!", alertContents: "The server returned an invalid response while attempting to verify your login credentials. Please try again later!")
                })
                // Exit
                return
                
            } else if( tokenRenewalState!["status"] as! String == "renewed_but_failed" && tokenRenewalState!["reason"] as! String == "keychain_failed" ) {
                
                // We failed to renew the login token, tell the user on the main thread
                dispatch_async(dispatch_get_main_queue(), {
                    // Remove the activity indicator from the navigation bar
                    self.navigationItem.leftBarButtonItem = self.navigationItemRefreshButton
                    // Hide activity indicator on the Status Bar
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    // Tell the user where we hit a snag
                    CommonUtils.showDefaultAlertToUser(self, title: "Hit a Snag!", alertContents: "We failed to save your fresh login token into Keychain. Please try again later!")
                })
                // Exit
                return
                
            } else if( tokenRenewalState!["status"] as! String == "no_renewal" && tokenRenewalState!["reason"] as! String == "invalid_cred" ) {
                
                // We failed to renew the login token, tell the user on the main thread
                dispatch_async(dispatch_get_main_queue(), {
                    // Remove the activity indicator from the navigation bar
                    self.navigationItem.leftBarButtonItem = self.navigationItemRefreshButton
                    // Hide activity indicator on the Status Bar
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    // Tell the user where we hit a snag
                    CommonUtils.showDefaultAlertToUser(self, title: "Hit a Snag!", alertContents: "Your login credentials have expired. Please try logout and log back in to create new Location Logs.")
                })
                // Exit
                return
                
            } else if( ( tokenRenewalState!["status"] as! String == "no_renewal" && tokenRenewalState!["reason"] as! String == "not_needed" ) ||
                       ( tokenRenewalState!["status"] as! String == "renewed" && tokenRenewalState!["reason"] == nil ) ) {
                
                // Perfect, just proceed with the rest of the job
                
            }
            
            // Fetch necessary information
            let awsEndpoint: String = CommonUtils.fetchFromPropertiesList("endpoints", fileExtension: "plist", key: "awsEC2EndpointURL")!
            let getMiniLogsURL: String = CommonUtils.fetchFromPropertiesList("endpoints", fileExtension: "plist", key: "fetchMiniLogsURL")!
            let userName: String! = KeychainWrapper.defaultKeychainWrapper().stringForKey("LocNotes-username")!
            let userLoginToken: String! = KeychainWrapper.defaultKeychainWrapper().stringForKey("LocNotes-loginToken")!
            
            // Create a synchronous request here
            let syncRequestURL: NSURL! = NSURL(string: "http://" + awsEndpoint + getMiniLogsURL)
            let syncSession: NSURLSession! = NSURLSession.sharedSession()
            
            let syncRequest: NSMutableURLRequest! = NSMutableURLRequest(URL: syncRequestURL)
            syncRequest.HTTPMethod = "POST"
            syncRequest.cachePolicy = .ReloadIgnoringLocalCacheData
            syncRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
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
            
            // Process the response
            var logIDsToDelete: [String] = []
            var logIDsToUpdate: [String] = []
            var logIDsToAdd: [String] = []
            
            if( syncResponse?.error != nil ) {
                // Tell the user; and return
                dispatch_async(dispatch_get_main_queue(), {
                    // Remove the activity indicator from the navigation bar
                    self.navigationItem.leftBarButtonItem = self.navigationItemRefreshButton
                    // Hide activity indicator on the Status Bar
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    // Also, alert the user
                    CommonUtils.showDefaultAlertToUser(self, title: "Hit a snag!", alertContents: "The server returned an invalid response. Please try again later!")
                })
                // Now, return
                return
            }
            
            // Else, process the JSON
            do {
                // Parse the JSON
                let jsonResponse: Array<AnyObject> = try NSJSONSerialization.JSONObjectWithData(syncResponse!.data!, options: NSJSONReadingOptions()) as! Array<AnyObject>
                
                // For each location log in the JSON, iterate over the Location Logs we've got and:
                //   1) See if it exists in our list; and,
                //   2) If it does exist, if the update time is newer than the one we have
                // Also check if any have been deleted
                
                for locationLog in jsonResponse {
                    // Extract information out of it now
                    let locationLogParsed: [String: AnyObject] = (locationLog as? [String: AnyObject])!
                    // Extract the Log ID and try to find it
                    var logIDFound: Bool = false
                    for locLogFromCoreData in self.locationLogs {
                        if locLogFromCoreData.logID == locationLogParsed["locationlogid"] as? String {
                            logIDFound = true
                            // Compare dates
                            let locLogUpdatedDate: Double! = (locationLogParsed["lastupdateddate"] as? NSNumber)?.doubleValue
                            if locLogUpdatedDate != Double(locLogFromCoreData.updateDate!) {
                                // Something has changed so we gotta update it
                                logIDsToUpdate.append(locLogFromCoreData.logID!)
                            }
                            // Break as we found it
                            break
                        }
                    }
                    // If it wasn't found, we gotta update and fetch the new one
                    if !logIDFound {
                        logIDsToAdd.append(locationLogParsed["locationlogid"] as! String)
                    }
                }
                
                // Check for deleted one
                for locLogFromCoreData in self.locationLogs {
                    var found: Bool = false
                    // Iterate to see if we find
                    for locationLog in jsonResponse {
                        // Parse this JSON Block
                        let locationLogParsed: [String: AnyObject] = (locationLog as? [String: AnyObject])!
                        // Check
                        if locLogFromCoreData.logID == locationLogParsed["locationlogid"] as? String {
                            found = true
                            break
                        }
                    }
                    // If not found, then we gotta delete
                    if !found {
                        logIDsToDelete.append(locLogFromCoreData.logID!)
                    }
                }
                
                // Once, we've got that list
                self.updateLocationLogs(logIDsToAdd, logIDsToUpdate: logIDsToUpdate, logIDsToDelete: logIDsToDelete)
                // And exit:
                return
                
            } catch {
                // Tell the user; and return
                dispatch_async(dispatch_get_main_queue(), {
                    // Remove the activity indicator from the navigation bar
                    self.navigationItem.leftBarButtonItem = self.navigationItemRefreshButton
                    // Hide activity indicator on the Status Bar
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    // Also, alert the user
                    CommonUtils.showDefaultAlertToUser(self, title: "Hit a snag!", alertContents: "The server returned an invalid response. Please try again later!")
                })
                // Now, return
                return
            }
        })
    }
    
    // MARK: - Update Location Logs function here
    func updateLocationLogs(logIDsToAdd: [String], logIDsToUpdate: [String], logIDsToDelete: [String]) {
        
        let totalLogCount: Int = logIDsToAdd.count + logIDsToUpdate.count + logIDsToDelete.count
        let awsS3BucketName: String! = CommonUtils.fetchFromPropertiesList("amazon-aws-credentials", fileExtension: "plist", key: "s3bucketname")
        
        // Update the UI to show progress view and scroll to the top
        dispatch_async(dispatch_get_main_queue(), {
            self.tableViewLoadingCellShown = true
            self.tableViewLoadingCellProgressText = "Processing 0 of \(totalLogCount) Location Logs"
            self.tableViewLoadingCellProgressValue = 0
            // Force update the TableView
            self.locationLogsTableView.reloadData()
            // Scroll to the top of the TableView
            self.locationLogsTableView.setContentOffset(CGPointZero, animated: true)
        })
        
        // Okay, now download all the Location Logs and save the JSON Array
        var freshLocationLogs: Array<[String: AnyObject]>? = nil
        
        dispatch_barrier_async(self.refreshLogQueue, {
            // Create a synchronous request to the server to fetch all the Location Logs for this user
            
            // Fetch necessary information
            let awsEndpoint: String = CommonUtils.fetchFromPropertiesList("endpoints", fileExtension: "plist", key: "awsEC2EndpointURL")!
            let getMiniLogsURL: String = CommonUtils.fetchFromPropertiesList("endpoints", fileExtension: "plist", key: "fetchAllLocationLogsURL")!
            let userName: String! = KeychainWrapper.defaultKeychainWrapper().stringForKey("LocNotes-username")!
            let userLoginToken: String! = KeychainWrapper.defaultKeychainWrapper().stringForKey("LocNotes-loginToken")!
            
            // Create a synchronous request here
            let syncRequestURL: NSURL! = NSURL(string: "http://" + awsEndpoint + getMiniLogsURL)
            let syncSession: NSURLSession! = NSURLSession.sharedSession()
            
            let syncRequest: NSMutableURLRequest! = NSMutableURLRequest(URL: syncRequestURL)
            syncRequest.HTTPMethod = "POST"
            syncRequest.cachePolicy = .ReloadIgnoringLocalCacheData
            syncRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
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
            
            // Process the response
            if( syncResponse?.error != nil ) {
                // Tell the user; and return
                dispatch_async(dispatch_get_main_queue(), {
                    // Remove the activity indicator from the navigation bar
                    self.navigationItem.leftBarButtonItem = self.navigationItemRefreshButton
                    // Hide activity indicator on the Status Bar
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    // Clean up progress view
                    self.tableViewLoadingCellShown = false
                    self.tableViewLoadingCellProgressValue = 0
                    self.tableViewLoadingCellProgressText = ""
                    self.locationLogsTableView.reloadData()
                    // Also, alert the user
                    CommonUtils.showDefaultAlertToUser(self, title: "Hit a snag!", alertContents: "The server returned an invalid response. Please try again later!")
                })
                // Now, return
                return
            }
            
            // Else, process the JSON
            do {
                // Parse the JSON
                let jsonResponse: Array<AnyObject> = try NSJSONSerialization.JSONObjectWithData(syncResponse!.data!, options: NSJSONReadingOptions()) as! Array<AnyObject>
                // Extract this up
                var finalJSON: Array<[String: AnyObject]> = Array<[String: AnyObject]>()
                for jsonObject in jsonResponse {
                    finalJSON.append((jsonObject as? [String: AnyObject])!)
                }
                // Save this
                freshLocationLogs = finalJSON
                
            } catch {
                // Tell the user; and return
                dispatch_async(dispatch_get_main_queue(), {
                    // Remove the activity indicator from the navigation bar
                    self.navigationItem.leftBarButtonItem = self.navigationItemRefreshButton
                    // Hide activity indicator on the Status Bar
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    // Clean up progress view
                    self.tableViewLoadingCellShown = false
                    self.tableViewLoadingCellProgressValue = 0
                    self.tableViewLoadingCellProgressText = ""
                    self.locationLogsTableView.reloadData()
                    // Also, alert the user
                    CommonUtils.showDefaultAlertToUser(self, title: "Hit a snag!", alertContents: "The server returned an invalid response. Please try again later!")
                })
                // Now, return
                return
            }
        })
        
        // First, let us add all the necessary logs
        dispatch_barrier_async(self.refreshLogQueue, {
            // Check if we should proceed
            if( freshLocationLogs == nil ) {
                return      //  Nope!
            }
            
            // Go over each of the logs to be added
            var logsAdded: Int = 0
            
            for logToBeAdded in logIDsToAdd {
                // Find this Log ID in the JSON Array
                for freshJSONLocationLog in freshLocationLogs! {
                    if freshJSONLocationLog["logid"] as! String == logToBeAdded {
                        
                        // We've found the log to be added
                        // First, extract all the image IDs
                        var imagesArray: Array<[String: AnyObject]> = Array<[String: AnyObject]>()
                        var imageS3IDs: [String] = []
                        for image in ((freshJSONLocationLog["images"]) as! Array<AnyObject>) {
                            let imageObject: [String: AnyObject] = (image as? [String: AnyObject])!
                            
                            imagesArray.append(imageObject)
                            imageS3IDs.append(imageObject["s3id"] as! String)
                        }
                        // Second, download them all from Amazon AWS
                        do {
                            try NSFileManager.defaultManager().createDirectoryAtURL(
                                NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("amazons3download"),
                                withIntermediateDirectories: true,
                                attributes: nil)
                        } catch {
                            // Maybe it exists already?
                        }
                        
                        var imageCountDone: Int = 0
                        
                        for imageS3ID in imageS3IDs {
                            // Create the request
                            let awsDownloadRequest: AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
                            let localFileName: String = NSProcessInfo.processInfo().globallyUniqueString.stringByAppendingString(".png")
                            awsDownloadRequest.bucket = awsS3BucketName
                            awsDownloadRequest.key = "\(logToBeAdded)_\(imageS3ID).png"
                            awsDownloadRequest.downloadingFileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("amazons3download").URLByAppendingPathComponent(localFileName)
                            
                            let awsTransferManager: AWSS3TransferManager = AWSS3TransferManager.defaultS3TransferManager()
                            let awsTask: AWSTask = awsTransferManager.download(awsDownloadRequest)
                            awsTask.continueWithBlock({(task) -> AnyObject! in
                                if let _ = task.error {
                                    // What to do? Work on error handling
                                } else if let _ = task.exception {
                                    // What to do? Work on error handling
                                } else {
                                    // Successful
                                }
                                // We are suppose to return nil
                                return nil
                            })
                            
                            // Wait for it to end
                            while( !awsTask.completed ) {
                                // Sleep for one second
                                sleep(1)
                                // Now update the user with the progress of the upload
                                awsDownloadRequest.uploadProgress = {(bytesSent, totalBytesSent, totalBytesExpectedToSend) -> Void in
                                    // Calculate the fresh progress
                                    let uploadProgress: Float = Float(bytesSent / totalBytesExpectedToSend)
                                    let imagesDone: Float = uploadProgress + Float(imageCountDone)
                                    let percentLogDone: Float = imagesDone / Float(imageS3IDs.count)
                                    let totalLogsDone: Float = percentLogDone + Float(logsAdded)
                                    
                                    let finalProgress: Float = Float(totalLogsDone) / Float(totalLogCount)
                                    // Update the UI
                                    dispatch_async(dispatch_get_main_queue(), {
                                        self.tableViewLoadingCellProgressValue = finalProgress
                                        // Force update of the first row
                                        self.locationLogsTableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .None)
                                    })
                                }
                            }
                            
                            // Increment
                            imageCountDone = imageCountDone + 1
                            
                            // Update the progress bar
                            let percentImagesDone: Float = Float(imageCountDone) / Float(imageS3IDs.count)
                            dispatch_async(dispatch_get_main_queue(), {
                                self.tableViewLoadingCellProgressValue = Float(Float(logsAdded) + percentImagesDone) / Float(totalLogCount)
                                // Force update of the first row
                                self.locationLogsTableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .None)
                            })
                            
                            // Third, save them to CoreData with location points of each image
                            let imageData: NSData? = NSData(contentsOfURL: NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("amazons3download").URLByAppendingPathComponent(localFileName))
                            if( imageData != nil ) {
                                
                                // We can proceed to saving it in the CoreData
                                let theImage: UIImage = UIImage(data: imageData!)!
                                
                                guard let fullResolutionS3Image: FullResolutionS3Image = NSEntityDescription.insertNewObjectForEntityForName("FullResolutionS3Image", inManagedObjectContext: self.managedContext!) as? FullResolutionS3Image, let imageThumbnail: ImageThumbnail = NSEntityDescription.insertNewObjectForEntityForName("ImageThumbnail", inManagedObjectContext: self.managedContext!) as? ImageThumbnail else
                                {
                                    continue
                                    // What to do? Work on error handling, yet again :(
                                }
                                
                                // Fill out the information
                                fullResolutionS3Image.amazonS3link = "https://s3.amazonaws.com/\(awsS3BucketName!)/\(logToBeAdded)_\(imageS3ID).png"
                                fullResolutionS3Image.image = UIImagePNGRepresentation(theImage)
                                fullResolutionS3Image.s3id = imageS3ID
                                fullResolutionS3Image.storeDate = NSNumber(longLong: Int64(NSDate().timeIntervalSince1970))
                                fullResolutionS3Image.respectiveLogID = logToBeAdded
                                
                                // Thumbnail Re-sizing Function
                                func resizeImage(image: UIImage, newHeight: CGFloat) -> UIImage {
                                    let scale = newHeight / image.size.height
                                    let newWidth = image.size.width * scale
                                    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
                                    image.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
                                    let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
                                    UIGraphicsEndImageContext()
                                    
                                    return newImage
                                }
                                
                                imageThumbnail.fullResS3id = imageS3ID
                                imageThumbnail.image = UIImagePNGRepresentation(resizeImage(theImage, newHeight: 128))
                                imageThumbnail.respectiveLogID = logToBeAdded
                                
                                // Save the new objects
                                do {
                                    try self.managedContext?.save()
                                } catch {
                                    // What to do? Work on error handling
                                }
                            }
                        }
                        // Fourth, create a CoreData object for the entire LocationLog itself
                        guard let locationLog: LocationLog = NSEntityDescription.insertNewObjectForEntityForName("LocationLog", inManagedObjectContext: self.managedContext!) as? LocationLog else
                        {
                            continue
                        }
                        
                        // Fill out the information
                        locationLog.addedDate = (freshJSONLocationLog["publishdate"] as? NSNumber)?.doubleValue
                        locationLog.imageS3ids = imageS3IDs.joinWithSeparator(";")
                        locationLog.locationNames = freshJSONLocationLog["locnames"] as? String
                        locationLog.logDesc = freshJSONLocationLog["desc"] as? String
                        locationLog.logID = logToBeAdded
                        locationLog.logTitle = freshJSONLocationLog["title"] as? String
                        locationLog.updateDate = (freshJSONLocationLog["lastupdateddate"] as? NSNumber)?.doubleValue
                        
                        // Attempt to save it now
                        do {
                            try self.managedContext?.save()
                        } catch {
                            continue
                        }
                        
                        // Increment
                        logsAdded = logsAdded + 1
                        // Update progress
                        dispatch_async(dispatch_get_main_queue(), {
                            // Update Progress
                            self.tableViewLoadingCellProgressText = "Processing \(logsAdded) of \(totalLogCount) Location Logs"
                            self.tableViewLoadingCellProgressValue = Float(logsAdded) / Float(totalLogCount)
                            // Force update of the first row
                            self.locationLogsTableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .None)
                        })
                        
                    }
                }
            }
        })
        
        // Second, let us update all the necessary logs
        // TODO: We shouldn't be reaching here in the first place; right now I am not dealing with updates
        
        // Third, let us delete all the necessary logs
        dispatch_barrier_async(self.refreshLogQueue, {
            // Check if we should proceed
            if( freshLocationLogs == nil ) {
                return      //  Nope!
            }
            
            var s3IDsToDelete: [String] = [] // Also collect the S3 IDs to be deleted
            
            // Iterate over each of the Log IDs to be delete
            for logIDtoDelete in logIDsToDelete {

                let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "LocationLog")
                do {
                    let results = try self.managedContext?.executeFetchRequest(fetchRequest)
                    let locationLogs: [LocationLog] = results as! [LocationLog]
                    
                    // Iterate over them and see which one should be delete
                    for locationLog in locationLogs {
                        if locationLog.logID == logIDtoDelete {
                            // Save all the S3 IDs to be deleted
                            if( locationLog.imageS3ids != nil && !(locationLog.imageS3ids?.isEmpty)! ) {
                                for s3id in (locationLog.imageS3ids?.componentsSeparatedByString(";"))! {
                                    s3IDsToDelete.append("\(locationLog.logID!)_\(s3id)")
                                }
                            }
                            // Ask CoreData to delete
                            self.managedContext?.deleteObject(locationLog)
                            // Ask Context To Save It
                            try self.managedContext?.save()
                            // We found it so:
                            break
                        }
                    }
                } catch {  }
                
            }
            
            if( s3IDsToDelete.count != 0 ) {
                // We've got S3 Image to delete from user's CoreData
            
                let imagesFetchRequest: NSFetchRequest = NSFetchRequest(entityName: "FullResolutionS3Image")
                do {
                    let imageResults = try self.managedContext?.executeFetchRequest(imagesFetchRequest)
                    let images: [FullResolutionS3Image] = imageResults as! [FullResolutionS3Image]
                    
                    // Iterate over them and see which one to delete
                    for image in images {
                        if s3IDsToDelete.contains("\(image.respectiveLogID!)_\(image.s3id!)") {
                            // Remove this image
                            self.managedContext?.deleteObject(image)
                            // Ask Context to save the changes
                            try self.managedContext?.save()
                        }
                    }
                } catch {  }
                
                let thumbnailFetchRequest: NSFetchRequest = NSFetchRequest(entityName: "ImageThumbnail")
                do {
                    let thumbnailResults = try self.managedContext?.executeFetchRequest(thumbnailFetchRequest)
                    let thumbnails: [ImageThumbnail] = thumbnailResults as! [ImageThumbnail]
                    
                    // Iterate over them and see which ones to delete
                    for thumbnail in thumbnails {
                        if s3IDsToDelete.contains("\(thumbnail.respectiveLogID!)_\(thumbnail.fullResS3id!)") {
                            // Remove this thumbnail
                            self.managedContext?.deleteObject(thumbnail)
                            // Ask Context to save changes
                            try self.managedContext?.save()
                        }
                    }
                } catch {  }
                
            }
            
            // Show done processing
            dispatch_async(dispatch_get_main_queue(), {
                // Update the label and progress
                self.tableViewLoadingCellProgressText = "Done processing all Location Logs"
                self.tableViewLoadingCellProgressValue = 1
                // Force an update of the TableView
                self.locationLogsTableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .None)
            })
            // Sleep for a second
            sleep(1)
        })
        
        // Lastly, force update the UI
        dispatch_barrier_async(self.refreshLogQueue, {
            // Check if we should proceed
            if( freshLocationLogs == nil ) {
                return      // Nope!
            }
            
            // Clear up some memory
            self.managedContext?.refreshAllObjects()
            
            // Else, clean up on the main thread
            dispatch_async(dispatch_get_main_queue(), {
                // Replace the loading navigation bar item and update the status bar
                self.navigationItem.leftBarButtonItem = self.navigationItemRefreshButton
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                
                // Force fetching of new logs
                self.fetchLocationLogs()
                
                // Also, hide the progress view in the TableView
                self.tableViewLoadingCellShown = false
                self.tableViewLoadingCellProgressValue = 0
                self.tableViewLoadingCellProgressText = ""
                
                // Force a refresh of the TableView
                self.locationLogsTableView.reloadData()
                
                // Scroll to the top
                self.locationLogsTableView.setContentOffset(CGPointZero, animated: true)
            })
        })
    }
    
    // MARK: - Segue actions handler here
    @IBAction func unwindSegue(segue: UIStoryboardSegue) {
        if( segue.sourceViewController.isKindOfClass(NewUserLocationLogViewController) ||
            segue.sourceViewController.isKindOfClass(UserSettingsViewController) ) {
            // Call the function to populate the LocationLogs from CoreData
            self.fetchLocationLogs()
            // And, refresh the TableView
            self.locationLogsTableView.reloadData()
            // Scroll to the top of the TableView
            self.locationLogsTableView.setContentOffset(CGPointZero, animated: true)
        }
    }

}
