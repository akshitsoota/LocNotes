//
//  ShowLocationLogViewController.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/18/16.
//  Copyright © 2016 axe. All rights reserved.
//

import CoreData
import MapKit
import UIKit

class ShowLocationLogViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,
                                     UITableViewDelegate, UITableViewDataSource, UIViewControllerPreviewingDelegate
{

    @IBOutlet weak var locationLogTitleHolder: UIView!
    @IBOutlet weak var locationLogTitleLabel: UILabel!
    @IBOutlet weak var locationLogTimesLabel: UILabel!
    @IBOutlet weak var locationLogDescHolder: UIView!
    @IBOutlet weak var locationLogDescLabel: UILabel!
    @IBOutlet weak var locationLogPhotosHolder: UIView!
    @IBOutlet weak var locationLogPhotosView: UICollectionView!
    @IBOutlet weak var locationLogLocationsVisitedHolder: UIView!
    @IBOutlet weak var locationLogLocationsVisitedTable: UITableView!
    @IBOutlet weak var locationLogShowLocationsMap: UIButton!
    // Holds the bottom border of the Description Field
    var locationLogDescHolderBottomBorder: UIView?
    // Holds the LocationLog, thumbnails and image locations that will be shown to the user
    var locationLogShown: LocationLog?
    var locationLogImageLocations: Dictionary<String, CLLocation> = Dictionary<String, CLLocation>()
    var locationLogThumbnails: Dictionary<String, ImageThumbnail> = Dictionary<String, ImageThumbnail>()
    var locationLogThumbnailScales: Dictionary<String, Double> = Dictionary<String, Double>()
    var explodedS3imageIDsList: [String] = []
    // Holds the locations the user visited along with the respective LatLng
    var locationsVisited: [String] = []
    var latLngsVisited: [CLLocationCoordinate2D] = []
    // Holds the loading screen
    var loadingScreen: UIView?
    
    // Holds the destination ViewSetup required for the LocationLogMapViewController
    var destinationViewSetup: LocationLogMapViewViewController.ViewSetup = .Unknown
    // SingleImagePoint
    var sipIndex: Int?
    // SingleLocationPoint
    var slpIndex: Int?
    
    // Dispatch Queues
    let coreDataQueue = dispatch_queue_create("CoreDataWorkQueue", DISPATCH_QUEUE_CONCURRENT)
    // Holds the CoreData Managed Context
    var managedContext: NSManagedObjectContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add contents to the view
        self.addContentToView()
        // And now setup the view
        self.setupView()
        // Fetch from CoreData
        self.fetchFromCoreData()
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
    
    // MARK: - Setup View Function(s)
    
    func addContentToView() {
        // Setup the text labels on the screen
        self.locationLogTitleLabel.text = self.locationLogShown?.logTitle
        self.locationLogDescLabel.text = self.locationLogShown?.logDesc
        // For time label
        let addedTime: Double = (self.locationLogShown?.addedDate?.doubleValue)!
        let addedTimeOffset: String = NSDate().offsetFrom(NSDate(timeIntervalSince1970: addedTime))
        let updatedTime: Double = (self.locationLogShown?.updateDate?.doubleValue)!
        let updateTimeOffset: String = NSDate().offsetFrom(NSDate(timeIntervalSince1970: updatedTime))
        if( addedTime == updatedTime ) {
            self.locationLogTimesLabel.text = "added and updated \(updateTimeOffset)"
        } else {
            self.locationLogTimesLabel.text = "added \(addedTimeOffset) and updated \(updateTimeOffset)"
        }
        
        // Explode the S3 IDs into a String Array
        var s3IDs: [String] = []
        for s3id in (self.locationLogShown?.imageS3ids?.componentsSeparatedByString(";"))! {
            if( !s3id.isEmpty ) {
                s3IDs.append(s3id)
            }
        }
        // Save it
        self.explodedS3imageIDsList = s3IDs
        
        // Explode the Locations Visited into the Array along with the respective LatLngs
        for locName in (self.locationLogShown?.locationNames?.componentsSeparatedByString(";;;"))! {
            if( !locName.isEmpty ) {
                self.locationsVisited.append(locName)
            }
        }
        
        for locPoint in (self.locationLogShown?.locationPoints?.componentsSeparatedByString(";"))! {
            if( !locPoint.isEmpty ) {
                let splitted: [String] = locPoint.componentsSeparatedByString(",")
                let latitude: Double = (splitted[0] as NSString).doubleValue
                let longitude: Double = (splitted[1] as NSString).doubleValue
                
                self.latLngsVisited.append(CLLocationCoordinate2DMake(latitude, longitude))
            }
        }
    }
    
    func setupView() {
        
        // Setup the borders for the View Holders
        func generateTopBorder(forView: UIView!) {
            let topBorder: UIView = UIView(frame: CGRectMake(0, 0, forView.frame.size.width, 1))
            topBorder.backgroundColor = UIColor.darkGrayColor()
            // Add it
            forView.addSubview(topBorder)
        }
        
        func generateBottomBorder(forView: UIView!) -> UIView! {
            let bottomBorder: UIView = UIView(frame: CGRectMake(0, forView.frame.size.height - 1, forView.frame.size.width, 1))
            bottomBorder.backgroundColor = UIColor.darkGrayColor()
            // Add it
            forView.addSubview(bottomBorder)
            // Return it as well:
            return bottomBorder
        }
        
        // Add the top borders for the holders
        generateTopBorder(self.locationLogTitleHolder)
        generateTopBorder(self.locationLogDescHolder)
        generateTopBorder(self.locationLogPhotosHolder)
        generateTopBorder(self.locationLogLocationsVisitedHolder)
        // Add the bottom borders for the holders
        generateBottomBorder(self.locationLogTitleHolder)
        if( self.locationLogDescHolderBottomBorder != nil ) {
            self.locationLogDescHolderBottomBorder!.removeFromSuperview()
        }
        self.locationLogDescHolderBottomBorder = generateBottomBorder(self.locationLogDescHolder)
        generateBottomBorder(self.locationLogPhotosHolder)
        generateBottomBorder(self.locationLogLocationsVisitedHolder)
        
        // Setup the background color for the CollectionView
        self.locationLogPhotosView.backgroundColor = UIColor.clearColor()
        // Let us handle the data source and delegate for the CollectionView of the photos
        self.locationLogPhotosView.dataSource = self
        // We should handle the FlowLayout for the Photos CollectionView as well
        self.locationLogPhotosView.delegate = self
        
        // Setup background view for CollectionView if the user has no photos
        if( self.explodedS3imageIDsList.count == 0 ) {
            let nibArray: [AnyObject] = NSBundle.mainBundle().loadNibNamed("NoPhotosInLocationLogView", owner: self, options: nil)
            let bgView = nibArray[0] as! UIView
            bgView.frame.size = self.locationLogPhotosView.frame.size
            self.locationLogPhotosView.backgroundView = bgView
        } else {
            self.locationLogPhotosView.backgroundView = UIView(frame: CGRectZero)
        }
        
        // Setup the Locations Visited Table View
        self.locationLogLocationsVisitedTable.dataSource = self
        self.locationLogLocationsVisitedTable.delegate = self
        
        // Hide "Map It Out" Button if necessary
        self.locationLogShowLocationsMap.hidden = (self.locationsVisited.count == 0)
        
        // Accept force touch on Collection View
        self.registerForPreviewingWithDelegate(self, sourceView: self.locationLogPhotosView)
        // Same for the TableView
        self.registerForPreviewingWithDelegate(self, sourceView: self.locationLogLocationsVisitedTable)
        
    }
    
    func fetchFromCoreData() {
        if( self.managedContext == nil ) {
            self.managedContext = AppDelegate().managedObjectContext
        }
        // Now fetch all the thumbnails
        let thumbnailFetchRequest: NSFetchRequest = NSFetchRequest(entityName: "ImageThumbnail")
        do {
            let thumbnailResults = try self.managedContext?.executeFetchRequest(thumbnailFetchRequest)
            let thumbnails: [ImageThumbnail] = thumbnailResults as! [ImageThumbnail]
            
            // Iterate over them and see which ones to delete
            for thumbnail in thumbnails {
                if thumbnail.respectiveLogID! == (self.locationLogShown?.logID)! &&
                   self.explodedS3imageIDsList.contains(thumbnail.fullResS3id!) {
                    // Save the thumbnail to the Dictionary of thumbnails we got
                    self.locationLogThumbnails[thumbnail.fullResS3id!] = thumbnail
                }
            }
        } catch {  }
        // Now iterate over the S3 Images and find the Thumbnail Scales and also save a location if there is any
        let imagesFetchRequest: NSFetchRequest = NSFetchRequest(entityName: "FullResolutionS3Image")
        do {
            let imageResults = try self.managedContext?.executeFetchRequest(imagesFetchRequest)
            let images: [FullResolutionS3Image] = imageResults as! [FullResolutionS3Image]
            
            // Iterate over them and see which one to delete
            for image in images {
                if image.respectiveLogID! == (self.locationLogShown?.logID)! &&
                   self.explodedS3imageIDsList.contains(image.s3id!) {
                    // Save the scale to the dictionary of scales
                    let imageObject: UIImage = UIImage(data: image.image!)!
                    self.locationLogThumbnailScales[image.s3id!] = Double(Double(imageObject.size.width) / Double(imageObject.size.height))
                    // Check for location
                    if( image.imageLocation != nil && !(image.imageLocation?.isEmpty)! ) {
                        let splitted: [String] = image.imageLocation!.componentsSeparatedByString(",")
                        // Collect the LatLng and save it in the dictionary
                        let location: CLLocation = CLLocation(latitude: Double(splitted[0])!, longitude: Double(splitted[1])!)
                        self.locationLogImageLocations[image.s3id!] = location
                    }
                }
            }
        } catch {  }
        // Clear up some memory
        self.managedContext?.refreshAllObjects()
    }
    
    // MARK: - UICollectionView Data Source
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.explodedS3imageIDsList.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // Return a cell for the given IndexPath
        let photoViewCell: PhotoCollectionViewCell! = collectionView.dequeueReusableCellWithReuseIdentifier("locationLogImage", forIndexPath: indexPath) as! PhotoCollectionViewCell
        let photoView: PhotoView = PhotoView()
        photoView.thumbnailImage = UIImage(data: self.locationLogThumbnails[self.explodedS3imageIDsList[indexPath.row]]!.image!)!
        photoView.photoViewIndex = indexPath.row
        photoViewCell.extraInformation = photoView
        photoViewCell.removePhotoButtonClickedFunction = self.openUpImageLocation
        photoViewCell.imageViewClickedFunction = self.openUpImage
        // The map button should only be shown if there is a mapped image
        photoViewCell.removeButton.hidden = (self.locationLogImageLocations[self.explodedS3imageIDsList[indexPath.row]] == nil)
        // Now that we've setup the thumbnail, return
        return photoViewCell
    }
    
    func openUpImageLocation(sender: AnyObject, extraInfo: PhotoView?) {
        // Check if we've got an associated location
        if( self.locationLogImageLocations[self.explodedS3imageIDsList[(extraInfo?.photoViewIndex)!]] != nil ) {
            // We've got a location to show on a map
            // Fill out information before performing the segue
            self.destinationViewSetup = .SingleImagePoint
            self.sipIndex = (extraInfo?.photoViewIndex)!
            // Perform the segue
            self.performSegueWithIdentifier("showMapView", sender: self)
        } else {
            // We shouldn't be here in the first place, but...
            // Tell the user we've got nothing for them
            CommonUtils.showDefaultAlertToUser(self, title: "Missing Location Info", alertContents: "The image has no location metadata attached with it. Try another image!")
        }
    }
    
    func openUpImage(sender: AnyObject, extraInfo: PhotoView?) {
        // Perform the segue and save the information in self.sipIndex
        self.sipIndex = (extraInfo?.photoViewIndex)!
        self.performSegueWithIdentifier("showImageView", sender: self)
    }
    
    // MARK: - UICollectionView Flow Layout Delegate
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: self.locationLogThumbnailScales[self.explodedS3imageIDsList[indexPath.row]]! * 128, height: 128)
    }
    
    // MARK: - UITableView Data Source
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if( self.locationsVisited.count == 0 ) {
            return 1        // Just tell the user that we've got nothing to show
        }
        return self.locationsVisited.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Dequeue the Cell
        let locationCell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("locationVisitedCell")!
        
        // Check if we've got any Location Visited
        if( self.locationsVisited.count == 0 ) {
            locationCell.textLabel?.text = "No locations to show!"
            // Return
            return locationCell
        }
        // Else, fill in the location name and return
        locationCell.textLabel?.text = self.locationsVisited[indexPath.row]
        return locationCell
    }
    
    // MARK: - UITableView Delegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Deselect the Table Cell
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        // Check if we've got anything to show the user
        if( self.locationsVisited.count == 0 ) {
            return
        }
        // Else, open it up in the map
        // Fill out information before performing the segue
        self.destinationViewSetup = .SingleLocationPoint
        self.slpIndex = indexPath.row
        // Perform the segue
        self.performSegueWithIdentifier("showMapView", sender: self)
    }
    
    // MARK: - UIViewControllerPreviewing Delegate
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // Try to find a location on the Collection View
        // CITATION: http://krakendev.io/peek-pop/
        
        if previewingContext.sourceView == self.locationLogPhotosView {
            if let indexPath = self.locationLogPhotosView.indexPathForItemAtPoint(location),
                let cellAttributes = self.locationLogPhotosView.layoutAttributesForItemAtIndexPath(indexPath) {
                // Setup the Peek
                previewingContext.sourceRect = cellAttributes.frame
                // Create the ViewController to be returned
                guard let toReturnVC: LocationLogImageViewViewController = self.storyboard?.instantiateViewControllerWithIdentifier("locationLogImageViewVC") as? LocationLogImageViewViewController else { return nil }
                // Fetch image from CoreData
                var coreDataImage: UIImage?
                let imagesFetchRequest: NSFetchRequest = NSFetchRequest(entityName: "FullResolutionS3Image")
                do {
                    let imageResults = try self.managedContext?.executeFetchRequest(imagesFetchRequest)
                    let images: [FullResolutionS3Image] = imageResults as! [FullResolutionS3Image]
                    
                    // Iterate over them and see which one to delete
                    for s3image in images {
                        if s3image.respectiveLogID! == (self.locationLogShown?.logID)! &&
                            s3image.s3id! == self.explodedS3imageIDsList[indexPath.row] {
                            // We found the image, so save it
                            coreDataImage = UIImage(data: s3image.image!)
                            // And break
                            break
                        }
                    }
                } catch {  }
                // Fill out the information
                toReturnVC.imageShown = coreDataImage
                toReturnVC.imageLocation = self.locationLogImageLocations[self.explodedS3imageIDsList[indexPath.row]]
                // Now, return
                return toReturnVC
            }
        }
        
        // Try to find a location on the Table View instead
        if previewingContext.sourceView == self.locationLogLocationsVisitedTable {
            if let indexPath = self.locationLogLocationsVisitedTable.indexPathForRowAtPoint(location) {
                // Setup the Peek
                previewingContext.sourceRect = self.locationLogLocationsVisitedTable.rectForRowAtIndexPath(indexPath)
                // Create the ViewController to be returned
                guard let toReturnVC: LocationLogMapViewViewController = self.storyboard?.instantiateViewControllerWithIdentifier("locationLogMapViewVC") as? LocationLogMapViewViewController else { return nil }
                // Fill out the information
                toReturnVC.locationTypeSetup = .SingleLocationPoint
                toReturnVC.slpLocationName = self.locationsVisited[indexPath.row]
                toReturnVC.slpLocationPoint = self.latLngsVisited[indexPath.row]
                // Now, return
                return toReturnVC
            }
        }
        
        // Else, return
        return nil
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        // Show the ViewController
        self.navigationController?.showViewController(viewControllerToCommit, sender: self)
    }
    
    // MARK: - Actions received here
    @IBAction func locationsVisitedShowMapButtonClicked(sender: UIButton) {
        // Show all the locations
        self.destinationViewSetup = .MultiLocationPoint
        // Perform the segue
        self.performSegueWithIdentifier("showMapView", sender: self)
    }
    
    @IBAction func navigationBarDeleteLocationLogClicked(sender: UIBarButtonItem) {
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
            var requestBody = "locationlogid=" + (self.locationLogShown?.logID)!
            
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
                        
                        // The Location Log was removed. Going to the previous screen (listing of user's location log) and forcing a refresh should help clear up
                        //   the necessary CoreData that is laying around for this deleted Location Log
                        
                        // Take the user to the login screen
                        dispatch_async(dispatch_get_main_queue(), {
                            self.loadingScreen!.removeFromSuperview()
                            // Exit this ViewController, go back and force a refresh
                            self.performSegueWithIdentifier("goBackUserLocationLogListing", sender: self)
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
    
    // MARK: - Segue handler
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Check the segue that we are performing
        if( segue.identifier == "showMapView" ) {
            // Grab the destination VC
            let destVC: LocationLogMapViewViewController = segue.destinationViewController as! LocationLogMapViewViewController
            // Check the destination setup type request
            if( self.destinationViewSetup == .SingleImagePoint && self.sipIndex != nil ) {
                // Fill out the info in destVC
                destVC.locationTypeSetup = .SingleImagePoint
                destVC.sipLocationPoint = self.locationLogImageLocations[self.explodedS3imageIDsList[self.sipIndex!]]
                destVC.sipImage = UIImage(data: self.locationLogThumbnails[self.explodedS3imageIDsList[self.sipIndex!]]!.image!)!
            } else if( self.destinationViewSetup == .SingleLocationPoint && self.slpIndex != nil ) {
                // Fill out the info in destVC
                destVC.locationTypeSetup = .SingleLocationPoint
                destVC.slpLocationPoint = self.latLngsVisited[self.slpIndex!]
                destVC.slpLocationName = self.locationsVisited[self.slpIndex!]
            } else if( self.destinationViewSetup == .MultiLocationPoint ) {
                // Fill out the info in destVC
                destVC.locationTypeSetup = .MultiLocationPoint
                destVC.mlpLocationNames = self.locationsVisited
                destVC.mlpLocationPoints = self.latLngsVisited
            }
        } else if( segue.identifier == "showImageView" ) {
            // Grab the destination VC
            let destVC: LocationLogImageViewViewController = segue.destinationViewController as! LocationLogImageViewViewController
            // Fetch the image from CoreData
            var coreDataImage: UIImage?
            let imagesFetchRequest: NSFetchRequest = NSFetchRequest(entityName: "FullResolutionS3Image")
            do {
                let imageResults = try self.managedContext?.executeFetchRequest(imagesFetchRequest)
                let images: [FullResolutionS3Image] = imageResults as! [FullResolutionS3Image]
                
                // Iterate over them and see which one to delete
                for s3image in images {
                    if s3image.respectiveLogID! == (self.locationLogShown?.logID)! &&
                       s3image.s3id! == self.explodedS3imageIDsList[self.sipIndex!] {
                        // We found the image, so save it
                        coreDataImage = UIImage(data: s3image.image!)
                        // And break
                        break
                    }
                }
            } catch {  }
            // Fill out the information
            destVC.imageShown = coreDataImage
            destVC.imageLocation = self.locationLogImageLocations[self.explodedS3imageIDsList[self.sipIndex!]]
        }
    }
    
    // MARK: - Orientation Change Listener
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()           // Let the super do its stuff
        // Setup the views
        setupView()
    }

}
