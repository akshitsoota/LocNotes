//
//  ShowLocationLogViewController.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/18/16.
//  Copyright © 2016 axe. All rights reserved.
//

import CoreData
import UIKit

class ShowLocationLogViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var locationLogTitleHolder: UIView!
    @IBOutlet weak var locationLogTitleLabel: UILabel!
    @IBOutlet weak var locationLogTimesLabel: UILabel!
    @IBOutlet weak var locationLogDescHolder: UIView!
    @IBOutlet weak var locationLogDescLabel: UILabel!
    @IBOutlet weak var locationLogPhotosHolder: UIView!
    @IBOutlet weak var locationLogPhotosView: UICollectionView!
    // Holds the bottom border of the Description Field
    var locationLogDescHolderBottomBorder: UIView?
    // Holds the LocationLog, thumbnails that will be shown to the user
    var locationLogShown: LocationLog?
    var locationLogThumbnails: Dictionary<String, ImageThumbnail> = Dictionary<String, ImageThumbnail>()
    var locationLogThumbnailScales: Dictionary<String, Double> = Dictionary<String, Double>()
    var explodedS3imageIDsList: [String] = []
    
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
        // Add the bottom borders for the holders
        generateBottomBorder(self.locationLogTitleHolder)
        if( self.locationLogDescHolderBottomBorder != nil ) {
            self.locationLogDescHolderBottomBorder!.removeFromSuperview()
        }
        self.locationLogDescHolderBottomBorder = generateBottomBorder(self.locationLogDescHolder)
        generateBottomBorder(self.locationLogPhotosHolder)
        
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
        /* self.locationVisitedTable.dataSource = self
        self.locationVisitedTable.delegate = self */
        
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
        // Now iterate over the S3 Images and find the Thumbnail Scales
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
        photoViewCell.extraInformation = photoView
        // Now that we've setup the thumbnail, return
        return photoViewCell
    }
    
    // MARK: - UICollectionView Flow Layout Delegate
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: self.locationLogThumbnailScales[self.explodedS3imageIDsList[indexPath.row]]! * 128, height: 128)
    }
    
    // MARK: - Orientation Change Listener
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()           // Let the super do its stuff
        // Setup the views
        setupView()
    }

}
