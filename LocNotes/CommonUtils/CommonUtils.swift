//
//  CommonUtils.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/2/16.
//  Copyright © 2016 axe. All rights reserved.
//

import MapKit
import UIKit

class CommonUtils {
    
    static func returnLoadingScreenView(target: UIViewController!) -> UIView! {
        // Get the view and set the frame
        let nibArray: [AnyObject] = NSBundle.mainBundle().loadNibNamed("LoadingScreenView", owner: target, options: nil)
        let toReturn = nibArray[0] as! UIView
        toReturn.frame = target.view.frame
        // Now return
        return toReturn
    }
    
    static func setLoadingTextOnLoadingScreenView(view: UIView!, newLabelContents: String) {
        // Try to set the label contents
        if( view.viewWithTag(2)!.isKindOfClass(UILabel) ) {
            let targetLabel: UILabel! = view.viewWithTag(2) as! UILabel
            // Now change the contents
            targetLabel.text = newLabelContents
        }
    }
    
    static func showDefaultAlertToUser(viewController: UIViewController!, title: String!, alertContents: String!) {
        let alert = UIAlertController(title: title, message: alertContents, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: ["Okay", "Got it"][Int(arc4random_uniform(2))], style: UIAlertActionStyle.Default, handler: nil))
        viewController.presentViewController(alert, animated: true, completion: nil)
    }
    
    static func isValidEmail(testStr:String) -> Bool {
        // print("validate calendar: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
    }
    
    static func returnProgressLoadingScreenView(target: UIViewController!) -> ProgressLoadingScreenView! {
        // Get the view and set the frame
        let nibArray: [AnyObject] = NSBundle.mainBundle().loadNibNamed("ProgressLoadingScreenView", owner: target, options: nil)
        let toReturn = nibArray[0] as! ProgressLoadingScreenView
        toReturn.frame = target.view.frame
        // Now return
        return toReturn
    }
    
    static func convertCircularRegionToMapViewRegion(region: CLCircularRegion) -> MKCoordinateRegion {
        return MKCoordinateRegionMakeWithDistance(region.center, region.radius * 2, region.radius * 2)
    }
    
    static func findMapItemFromMapItems(mapItems: [MKMapItem], latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> MKMapItem? {
        // Iterate over each of the MapItems
        for mapItem in mapItems {
            if( mapItem.placemark.coordinate.latitude == latitude &&
                mapItem.placemark.coordinate.longitude == longitude ) {
                // We found a match
                return mapItem
            }
        }
        // Else, return null
        return nil
    }
    
}