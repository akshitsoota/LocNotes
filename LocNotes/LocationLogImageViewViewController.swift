//
//  LocationLogImageViewViewController.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/19/16.
//  Copyright © 2016 axe. All rights reserved.
//

import MapKit
import UIKit

class LocationLogImageViewViewController: UIViewController {

    @IBOutlet weak var locationLogImageView: UIImageView!
    @IBOutlet weak var locationLogMapItButton: UIButton!
    // Holds the image to be shown
    var imageShown: UIImage?
    // Holds the location of where the image was taken
    var imageLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup the view
        self.locationLogImageView.image = self.imageShown
        // Also, see if the "Map It" button should be shown
        self.locationLogMapItButton.hidden = (self.imageLocation == nil)
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

    // MARK: - Actions here
    @IBAction func locationLogMapItButtonClicked(sender: AnyObject) {
        // Show the segue
        self.performSegueWithIdentifier("showMapView", sender: self)
    }
    
    // MARK: - Segue operations here
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if( segue.identifier == "showMapView" ) {
            // Save information to the destination view controller
            let destVC: LocationLogMapViewViewController = segue.destinationViewController as! LocationLogMapViewViewController
            destVC.locationTypeSetup = .SingleImagePoint
            destVC.sipImage = imageShown
            destVC.sipLocationPoint = imageLocation
        }
    }
}