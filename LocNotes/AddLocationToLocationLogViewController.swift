//
//  AddLocationToLocationLogViewController.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/8/16.
//  Copyright © 2016 axe. All rights reserved.
//

import MapKit
import UIKit

class AddLocationToLocationLogViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var cancelSearchButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchResultsHolder: UIView!
    @IBOutlet weak var searchResultsTable: UITableView!
    @IBOutlet weak var searchResultsProgress: UIActivityIndicatorView!
    // Holds the back button
    var navigationItemBackButton: UIBarButtonItem?
    // Holds the save button
    var navigationItemSaveButton: UIBarButtonItem?
    // Holds the discard button
    var navigationItemDiscardButton: UIBarButtonItem?
    // Holds the locations that will be shown in the search results
    var searchMatches: [MKMapItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup the view
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
    
    // MARK: - Setup view function here
    func setupView() {
        // Fetch all the navigation bar buttons
        for leftHandSideButton: UIBarButtonItem in self.navigationItem.leftBarButtonItems! {
            if leftHandSideButton.tag == 0 {
                // We've got the back button. Save it
                navigationItemBackButton = leftHandSideButton
            } else if leftHandSideButton.tag == 1 {
                // We've got the save button. Save it
                navigationItemSaveButton = leftHandSideButton
            }
        }
        
        navigationItemDiscardButton = self.navigationItem.rightBarButtonItem!
        
        // Reconfigure the navigation bar
        self.navigationItem.leftBarButtonItems = [navigationItemBackButton!]
        self.navigationItem.rightBarButtonItem = nil
        
        ///////
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = "United States"
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        search.startWithCompletionHandler { response, error in
            guard let response = response else {
                print("There was an error searching for: \(request.naturalLanguageQuery) error: \(error)")
                return
            }
            
            for item in response.mapItems {
                NSLog("\(item)")
                
                if let pmCircularRegion = item.placemark.region as? CLCircularRegion {
                    
                    let metersAcross = pmCircularRegion.radius * 2
                    
                    let region = MKCoordinateRegionMakeWithDistance(pmCircularRegion.center, metersAcross, metersAcross)
                    
                    self.mapView.region = region
                    
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: item.placemark.location!.coordinate.latitude, longitude: item.placemark.location!.coordinate.longitude)
                    self.mapView.addAnnotation(annotation)
                }
                
                
                self.searchResultsHolder.hidden = true
            }
        }
    }
    
    // MARK: - Actions received here
    @IBAction func backButtonClicked(sender: AnyObject) {
        
    }
    
    @IBAction func saveButtonClicked(sender: AnyObject) {
        
    }
    
    @IBAction func discardButtonClicked(sender: AnyObject) {
        
    }
    
}