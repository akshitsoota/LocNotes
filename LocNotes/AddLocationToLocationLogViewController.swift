//
//  AddLocationToLocationLogViewController.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/8/16.
//  Copyright © 2016 axe. All rights reserved.
//

import MapKit
import UIKit

class AddLocationToLocationLogViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,
                                              UISearchBarDelegate, MKMapViewDelegate
{

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
    // Holds the US Circular Region
    let unitedStatesCircularRegion: CLCircularRegion = CLCircularRegion(center: CLLocationCoordinate2DMake(+37.99472997, -95.85629150), radius: CLLocationDistance(3042542.54), identifier: "UnitedStates")
    // Holds the US Circular Region compatible with a MapView
    var unitedStatesCircularRegionMap: MKCoordinateRegion?
    // Holds the pins places on the MapView
    var mapViewPins: [MKPointAnnotation] = []
    // Holds the pins that have been confirmed by the user
    var mapViewConfirmedPins: [MKPointAnnotation] = []
    // Holds all the pins (confirmed and non-confirmed) pinned places on the MapView
    var mapViewAllShownPins: [MKPointAnnotation] = []
    // Holds all MKMapItems that are ever added to the MapView (may or may not be present on the MapView currently)
    var allMapItems: [MKMapItem] = []
    // Holds all MKMapItems of the confirmed locations by the user that are shown as green on the MapView
    var confirmedMapItems: [MKMapItem] = []
    
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
        
        // Configure the search results table view
        self.searchResultsTable.dataSource = self
        self.searchResultsTable.delegate = self
        
        // By default, hide the search results holder and the cancel search button
        self.searchResultsHolder.hidden = true
        self.cancelSearchButton.hidden = true
        
        // Center the MapView to the United States
        self.unitedStatesCircularRegionMap = CommonUtils.convertCircularRegionToMapViewRegion(self.unitedStatesCircularRegion)
        self.mapView.region = self.unitedStatesCircularRegionMap!
        
        // We should be fired when the search bar is queried
        self.searchBar.delegate = self
        
        // Hide the activity indicator by default
        self.searchResultsProgress.stopAnimating()
        self.searchResultsProgress.hidden = true
        
        // We should be dealing with the MapView Delegate
        self.mapView.delegate = self
    }
    
    // MARK: - UITableViewDelegate and UITableViewDataSource Delegate
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if( self.searchMatches.count == 0 &&
            !self.searchBar.text!.isEmpty ) {
            return 1 // We've to tell the user that we found nothing
        }
        return searchMatches.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let tableCell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("textCell")! as UITableViewCell
        if( self.searchMatches.count == 0 ) {
            // We found nothing, so tell the user
            tableCell.textLabel?.text = "No matches found 😞"
        } else {
            // We have got some matches, so pull up names from there
            tableCell.textLabel?.text = self.searchMatches[indexPath.row].placemark.title
        }
        // Now return it
        return tableCell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Hide all the search things
        self.searchBar.text = nil
        self.searchResultsHolder.hidden = true // Hide the Search Results Holder
        self.searchBar.resignFirstResponder() // Also hide the keyboard
        self.cancelSearchButton.hidden = true // Hide the cancel search button as well
        // Now, add the pin to the map
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: self.searchMatches[indexPath.row].placemark.location!.coordinate.latitude,
                                                       longitude: self.searchMatches[indexPath.row].placemark.location!.coordinate.longitude)
        self.mapViewPins.append(annotation) // Add it to our list that tracks all the MapView Pins
        self.mapViewAllShownPins.append(annotation) // Add it to our list that keeps track of all shown pins on MapView currently
        self.allMapItems.append(self.searchMatches[indexPath.row]) // Add it to our list of MKMapItems that the user ever added to the map
        self.mapView.addAnnotation(annotation) // Finally, add it to the MapView itself
        // Zoom to show all annotation pins
        self.mapView.showAnnotations(self.mapViewAllShownPins, animated: true)
        // Also, now update the buttons the Navigation Bar
        self.navigationItem.leftBarButtonItem = navigationItemSaveButton
        self.navigationItem.rightBarButtonItem = navigationItemDiscardButton
        // Remove all results and update the table
        self.searchMatches.removeAll()
        self.searchResultsTable.reloadData()
    }
    
    // MARK: - UISearchBarDelegate Delegate
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        // Show the search results table
        self.searchResultsHolder.hidden = false
        // Show the cancel search button
        self.cancelSearchButton.hidden = false
    }
    
    func searchBarHelper(searchBar: UISearchBar, searchText: String) {
        if( searchText.isEmpty ) {
            // Hide all the table results
            self.searchMatches.removeAll()
            // Force update the table
            self.searchResultsTable.reloadData()
            // And, we don't have to do anything else, so
            return
        }
        
        // Else, as we are performing a search, show the activity indicator
        self.searchResultsProgress.hidden = false
        self.searchResultsProgress.startAnimating()
        
        // And now perform the search
        performMapSearch(searchBar.text!)
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        // Call our helper function
        self.searchBarHelper(searchBar, searchText: searchText)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        // Hide the keyboard of the search bar
        searchBar.resignFirstResponder()
        // Now, call our helper function
        self.searchBarHelper(searchBar, searchText: searchBar.text!)
    }
    
    // MARK: - Search Query code here
    func performMapSearch(searchQuery: String) {
        // Create the search query
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchQuery
        
        // Now create the response handler and fire off the search
        let search = MKLocalSearch(request: request)
        search.startWithCompletionHandler {(response, error) in
            guard let response = response else {
                // Empty the search results previously got
                self.searchMatches.removeAll()
                // Hide the activity indicator
                self.searchResultsProgress.stopAnimating()
                self.searchResultsProgress.hidden = true
                // Force a reload of the table data
                self.searchResultsTable.reloadData()
                // Return
                return
            }
            
            // Empty the search results previously got
            self.searchMatches.removeAll()
            // Iterate over each of the results and add them all
            for item in response.mapItems {
                // Add each item to the list
                self.searchMatches.append(item)
            }
            // Also, now update the TableView
            self.searchResultsTable.reloadData()
            // Hide the activity indicator
            self.searchResultsProgress.stopAnimating()
            self.searchResultsProgress.hidden = true
        }
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if( self.mapViewConfirmedPins.contains(annotation as! MKPointAnnotation) ) {
            // This is one of the confirmed pins
            let annotationView: MKPinAnnotationView = MKPinAnnotationView.init(annotation: annotation, reuseIdentifier: nil)
            // Set the color and return
            annotationView.pinTintColor = UIColor.greenColor()
            // Now, return
            return annotationView
        }
        // Else, return
        return nil
    }
    
    // MARK: - Actions received here
    @IBAction func backButtonClicked(sender: AnyObject) {
        self.performSegueWithIdentifier("exitSegueBackToLocationLog", sender: self)
    }
    
    @IBAction func saveButtonClicked(sender: AnyObject) {
        // Reset the navigation bar
        self.navigationItem.leftBarButtonItem = self.navigationItemBackButton
        self.navigationItem.rightBarButtonItem = nil
        // Move all the pins from mapViewPins to mapViewConfirmedPins
        for mapViewPin in mapViewPins {
            // Remove the pin from the MapView
            self.mapView.removeAnnotation(mapViewPin)
            // Add to confirmed pins
            self.mapViewConfirmedPins.append(mapViewPin)
            // Add the respective MapItem to our confirmed MKMapItem list
            let correspondingMapItem: MKMapItem? = CommonUtils.findMapItemFromMapItems(self.allMapItems, latitude: mapViewPin.coordinate.latitude, longitude: mapViewPin.coordinate.longitude)
            if( correspondingMapItem != nil ) {
                // Add it to the list of confirmed ones
                self.confirmedMapItems.append(correspondingMapItem!)
            }
            // Re-add it to trigger the new color
            self.mapView.addAnnotation(mapViewPin)
        }
        // Remove from mapViewPins
        self.mapViewPins.removeAll()
    }
    
    @IBAction func discardButtonClicked(sender: AnyObject) {
        // Reset the navigation bar
        self.navigationItem.leftBarButtonItem = self.navigationItemBackButton
        self.navigationItem.rightBarButtonItem = nil
        // Remove all the pins on MapView
        for mapViewPin in mapViewPins {
            self.mapView.removeAnnotation(mapViewPin)
        }
        // Update current list of annotations shown on the screen
        self.mapViewAllShownPins = self.mapViewConfirmedPins
        // Clear out all the old pinds
        self.mapViewPins.removeAll()
        // Zoom out to the United States
        if( self.mapViewAllShownPins.count == 0 ) {
            self.mapView.setRegion(unitedStatesCircularRegionMap!, animated: true)
        } else {
            self.mapView.showAnnotations(self.mapViewAllShownPins, animated: true)
        }
    }
    
    @IBAction func cancelButtonClicked(sender: AnyObject) {
        // Hide the cancel button
        self.cancelSearchButton.hidden = true
        // Hide the search results holder
        self.searchResultsHolder.hidden = true
        self.searchResultsProgress.stopAnimating()
        self.searchResultsProgress.hidden = true
        // Clear out the SearchBar text box and hide the keyboard
        self.searchBar.text = nil
        self.searchBar.resignFirstResponder()
        // Clean out the results
        self.searchMatches.removeAll()
        self.searchResultsTable.reloadData()
    }
}