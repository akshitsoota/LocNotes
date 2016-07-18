//
//  ShowLocationLogViewController.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/18/16.
//  Copyright © 2016 axe. All rights reserved.
//

import CoreData
import UIKit

class ShowLocationLogViewController: UIViewController {

    @IBOutlet weak var locationLogTitleHolder: UIView!
    @IBOutlet weak var locationLogTitleLabel: UILabel!
    @IBOutlet weak var locationLogTimesLabel: UILabel!
    @IBOutlet weak var locationLogDescHolder: UIView!
    @IBOutlet weak var locationLogDescLabel: UILabel!
    @IBOutlet weak var locationLogPhotosHolder: UIView!
    @IBOutlet weak var locationLogPhotosView: UICollectionView!
    // Holds the bottom border of the Description Field
    var locationLogDescHolderBottomBorder: UIView?
    // Holds the LocationLog that will be shown to the user
    var locationLogShown: LocationLog?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add contents to the view
        self.addContentToView()
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
        
    }
    
    // MARK: - Orientation Change Listener
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()           // Let the super do its stuff
        // Setup the views
        setupView()
    }

}
