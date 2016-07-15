//
//  UserLocationLogsViewController.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/6/16.
//  Copyright © 2016 axe. All rights reserved.
//

import UIKit

class UserLocationLogsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var locationLogsTableView: UITableView!
    let TableCellReuseIdentifier_locationLogWithImage: String = "locationLogCellWithImage"
    let TableCellReuseIdentifier_locationLogWithoutImage: String = "locationLogCellWithoutImage"
    // Array that holds all the Location Logs fetched from Core Data
    var locationLogs: [LocationLog] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Fetch Location logs from CoreData
        fetchLocationLogs()
        // Set up the views
        setupViews()
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
        return locationLogs.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return UITableViewCell()
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
    
    // MARK: - Segue actions handler here
    @IBAction func unwindSegue(segue: UIStoryboardSegue) {
        if( segue.sourceViewController.isKindOfClass(NewUserLocationLogViewController) ) {
            // TODO
        }
    }

}
