//
//  LocationLogMapViewViewController.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/18/16.
//  Copyright © 2016 axe. All rights reserved.
//

import MapKit
import UIKit

class LocationLogMapViewViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    // Constants
    private let SingleImagePointMapViewRegionRadius: Double = 90000
    private let SingleLocationPointMapViewRegionRadius: Double = 300000
    // Holds the type of view that is being setup
    enum ViewSetup {
        case Unknown
        case SingleImagePoint
        case SingleLocationPoint
        case MultiLocationPoint
    }
    var locationTypeSetup: ViewSetup = .Unknown
    // Holds information for each of the ViewSetups
    // SingleImagePoint
    var sipLocationPoint: CLLocation?
    var sipImage: UIImage?
    // SingleLocationPoint
    var slpLocationPoint: CLLocationCoordinate2D?
    var slpLocationName: String?
    // MultiLocationPoint
    var mlpLocationNames: [String]?
    var mlpLocationPoints: [CLLocationCoordinate2D]?
    // Holds if it is the initial load or not
    var isInitialLoad: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    override func viewDidLayoutSubviews() {
        if( isInitialLoad ) {
            // Setup the views as necessary
            self.setupView()
            // Change the flag
            isInitialLoad = false
        }
    }
    
    // MARK: - Setup view here
    func setupView() {
        
        // Set default region for the MapView
        self.mapView.region = CommonUtils.convertCircularRegionToMapViewRegion(CLCircularRegion(center: CLLocationCoordinate2DMake(+37.99472997, -95.85629150), radius: CLLocationDistance(3042542.54), identifier: "UnitedStates"))
        // Check View Setup type
        if( self.locationTypeSetup == .SingleImagePoint ) {
            
            let imageLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: self.sipLocationPoint!.coordinate.latitude, longitude: self.sipLocationPoint!.coordinate.longitude)
            
            // Place annotation
            let pin: MKPointAnnotation = MKPointAnnotation()
            pin.coordinate = imageLocation
            pin.title = "Picture Location"
            
            self.mapView.addAnnotation(pin)
            // Open up this pin
            self.mapView.selectAnnotation(pin, animated: true)
            
            // Zoom to the location
            // CITATION: http://stackoverflow.com/a/11519772/705471
            
            let viewRegion: MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(imageLocation, SingleImagePointMapViewRegionRadius, SingleImagePointMapViewRegionRadius)
            let adjustedRegion: MKCoordinateRegion = mapView.regionThatFits(viewRegion)
            mapView.setRegion(adjustedRegion, animated: true)
            
        } else if( self.locationTypeSetup == .SingleLocationPoint ) {
            
            // Place annotation
            let pin: MKPointAnnotation = MKPointAnnotation()
            pin.coordinate = slpLocationPoint!
            pin.title = self.slpLocationName
            
            mapView.addAnnotation(pin)
            // Open up this pin
            self.mapView.selectAnnotation(pin, animated: true)
            
            // Zoom to the location
            // CITATION: http://stackoverflow.com/a/11519772/705471
            
            let viewRegion: MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(slpLocationPoint!, SingleLocationPointMapViewRegionRadius, SingleLocationPointMapViewRegionRadius)
            let adjustedRegion: MKCoordinateRegion = mapView.regionThatFits(viewRegion)
            mapView.setRegion(adjustedRegion, animated: true)
            
        } else if( self.locationTypeSetup == .MultiLocationPoint ) {
            
            var pinsArray: [MKPointAnnotation] = []
            // Iterate over each of the names and add the pin
            for idx in 0..<self.mlpLocationNames!.count {
                // Create the pin and add it to the MapView
                let pin: MKPointAnnotation = MKPointAnnotation()
                pin.coordinate = self.mlpLocationPoints![idx]
                pin.title = self.mlpLocationNames![idx]
                // Place it and add it to the array
                self.mapView.addAnnotation(pin)
                pinsArray.append(pin)
            }
            // Zoom to show all the pins
            self.mapView.showAnnotations(pinsArray, animated: true)
            
        }
        
    }

}
