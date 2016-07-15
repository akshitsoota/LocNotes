//
//  CommonUtils.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/2/16.
//  Copyright © 2016 axe. All rights reserved.
//

import SystemConfiguration
import Photos
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
    
    static func returnLoadingScreenView(target: UIViewController!, size: CGRect) -> UIView! {
        // Get the view and set the frame
        let nibArray: [AnyObject] = NSBundle.mainBundle().loadNibNamed("LoadingScreenView", owner: target, options: nil)
        let toReturn = nibArray[0] as! UIView
        toReturn.frame = size
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
    
    static func returnProgressLoadingScreenView(target: UIViewController!, size: CGRect!) -> ProgressLoadingScreenView! {
        // Get the view and set the frame
        let nibArray: [AnyObject] = NSBundle.mainBundle().loadNibNamed("ProgressLoadingScreenView", owner: target, options: nil)
        let toReturn = nibArray[0] as! ProgressLoadingScreenView
        toReturn.frame = size
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
    
    static func fetchFromPropertiesList(fileName: String, fileExtension: String, key: String) -> String? {
        // Fetch the values from the endpoints properties list
        // REFERENCE: http://www.kaleidosblog.com/nsurlsession-in-swift-get-and-post-data

        var keys: NSDictionary?
        
        if let path = NSBundle.mainBundle().pathForResource(fileName, ofType: fileExtension) {
            keys = NSDictionary(contentsOfFile: path)
        }
        if let dict = keys {
            let value: String! = dict[key] as! String
            return value
        }
        
        // Else, we'd a problem, so:
        return nil
    }
    
    static func fetchUIImageFromPHAsset(asset: PHAsset!) -> UIImage? {
        let photoManager: PHImageManager = PHImageManager.defaultManager()
        let fetchOptions: PHImageRequestOptions = PHImageRequestOptions()
        fetchOptions.synchronous = true
        
        var realImage: UIImage? = nil
        photoManager.requestImageDataForAsset(asset, options: fetchOptions) {(result, name, imageOrientation, info) in
            if( result != nil ) {
                realImage = UIImage(data: result!)
            }
        }
        
        // Return
        return realImage
    }
    
    // CITATION:
    // http://blog.appliedinformaticsinc.com/swift-sha256-ios-10-minute-quick-hack/
    // and
    // http://stackoverflow.com/questions/24044851/how-do-you-use-string-substringwithrange-or-how-do-ranges-work-in-swift
    
    static func generateSHA256(data : NSData) -> String {
        let res = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256(data.bytes, CC_LONG(data.length), UnsafeMutablePointer(res!.mutableBytes))
        
        var toReturn: String = "\(res!)".stringByReplacingOccurrencesOfString(" ", withString: "")
        toReturn = toReturn.substringWithRange(Range<String.Index>(toReturn.startIndex.advancedBy(1)..<toReturn.endIndex.advancedBy(-1)))
        
        return toReturn
    }
    
    static func generateSHA512(data : NSData) -> String {
        let res = NSMutableData(length: Int(CC_SHA512_DIGEST_LENGTH))
        CC_SHA512(data.bytes, CC_LONG(data.length), UnsafeMutablePointer(res!.mutableBytes))
        
        var toReturn: String = "\(res!)".stringByReplacingOccurrencesOfString(" ", withString: "")
        toReturn = toReturn.substringWithRange(Range<String.Index>(toReturn.startIndex.advancedBy(1)..<toReturn.endIndex.advancedBy(-1)))
        
        return toReturn
    }
    
    // CITATION:
    // http://stackoverflow.com/a/29244451/705471
    
    enum ConnectionStatus {
        case ConnectionTypeUnknown
        case ConnectionTypeNone
        case ConnectionTypeCellular
        case ConnectionTypeWiFi
    }
    
    static func findIntentConnectionType() -> ConnectionStatus {
        let reachability: SCNetworkReachabilityRef = SCNetworkReachabilityCreateWithName(nil, "8.8.8.8")!
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags()
        if SCNetworkReachabilityGetFlags(reachability, &flags) == false {
            return ConnectionStatus.ConnectionTypeUnknown
        }
        
        let isReachable: Bool = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection: Bool = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let isNetworkReachable: Bool = isReachable && !needsConnection
        
        if( !isNetworkReachable ) {
            return ConnectionStatus.ConnectionTypeNone
        } else if( (flags.rawValue & UInt32(SCNetworkReachabilityFlags.IsWWAN.rawValue)) != 0 ) {
            return ConnectionStatus.ConnectionTypeCellular
        } else {
            return ConnectionStatus.ConnectionTypeWiFi
        }
        
        /* SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, "8.8.8.8");
        SCNetworkReachabilityFlags flags;
        BOOL success = SCNetworkReachabilityGetFlags(reachability, &flags);
        CFRelease(reachability);
        if (!success) {
            return ConnectionTypeUnknown;
        }
        BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
        BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
        BOOL isNetworkReachable = (isReachable && !needsConnection);
        
        if (!isNetworkReachable) {
            return ConnectionTypeNone;
        } else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
            return ConnectionType3G;
        } else {
            return ConnectionTypeWiFi;
        }
        
        let rechability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "www.apple.com")
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags()
        
        if SCNetworkReachabilityGetFlags(rechability!, &flags) == false {
            return false
        }
        
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        
        return (isReachable && !needsConnection) */
    }
    
}

// CITATION:
// http://stackoverflow.com/a/34308158/705471
extension NSURLSession {
    
    func synchronousDataTaskWithURL(url: NSURL) -> (NSData?, NSURLResponse?, NSError?) {
        var data: NSData?, response: NSURLResponse?, error: NSError?
        
        let semaphore = dispatch_semaphore_create(0)
        
        dataTaskWithURL(url) {
            data = $0; response = $1; error = $2
            dispatch_semaphore_signal(semaphore)
            }.resume()
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        return (data, response, error)
    }
    
}


// CITATION:
// http://stackoverflow.com/a/35360697/705471
extension String {
    func fromBase64() -> String
    {
        let data = NSData(base64EncodedString: self, options: NSDataBase64DecodingOptions(rawValue: 0))
        return String(data: data!, encoding: NSUTF8StringEncoding)!
    }
    
    func toBase64() -> String
    {
        let data = self.dataUsingEncoding(NSUTF8StringEncoding)
        return data!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
    }
}

