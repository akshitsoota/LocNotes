//
//  UserAuthentication.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/14/16.
//  Copyright © 2016 axe. All rights reserved.
//

import Foundation

class UserAuthentication {
    
    // Return the Authorization Header required for Auth-based requests to the EC2 Backend
    static func generateAuthorizationHeader(username: String?, userLoginToken: String?) -> String {
        let authValue: String = "\(username!):\(userLoginToken!)".toBase64()
        return "Basic \(authValue)"
    }
    
    // Requests the EC2 backend for a new login token for the logged in user (synchronous method)
    static func renewLoginToken() -> NSDictionary? {
        // Fetch the common information first
        let awsEndpoint: String = CommonUtils.fetchFromPropertiesList("endpoints", fileExtension: "plist", key: "awsEC2EndpointURL")!
        let renewLoginTokenURL: String = CommonUtils.fetchFromPropertiesList("endpoints", fileExtension: "plist", key: "renewLoginTokenURL")!
        // Fetch User Information
        let userName: String! = KeychainWrapper.defaultKeychainWrapper().stringForKey("LocNotes-username")!
        let userLoginToken: String! = KeychainWrapper.defaultKeychainWrapper().stringForKey("LocNotes-loginToken")!
        let userTokenExpiry: Double! = KeychainWrapper.defaultKeychainWrapper().doubleForKey("LocNotes-tokenExpiry")!
        // To return
        let toReturn: NSMutableDictionary = NSMutableDictionary()
        
        // Query our backend; Start the synchronous request
        let syncRequestURL: NSURL! = NSURL(string: "http://" + awsEndpoint + renewLoginTokenURL)
        let syncSession: NSURLSession! = NSURLSession.sharedSession()
        
        let syncRequest: NSMutableURLRequest! = NSMutableURLRequest(URL: syncRequestURL)
        syncRequest.HTTPMethod = "POST"
        syncRequest.cachePolicy = .ReloadIgnoringLocalCacheData
        syncRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Let us form a dictionary of <K, V> pairs to be sent
        // REFERENCE: http://stackoverflow.com/a/28009796/705471
        let requestParams: Dictionary<String, String>! = ["username": userName,
                                                          "logintoken": userLoginToken,
                                                          "logintokenexpiry": String(userTokenExpiry)]
        var firstParamAdded: Bool! = false
        let paramKeys: Array<String>! = Array(requestParams.keys)
        var requestBody = ""
        for key in paramKeys {
            if( !firstParamAdded ) {
                requestBody += key + "=" + requestParams[key]!
                firstParamAdded = true
            } else {
                requestBody += "&" + key + "=" + requestParams[key]!
            }
        }
        
        requestBody = requestBody.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        syncRequest.HTTPBody = requestBody.dataUsingEncoding(NSUTF8StringEncoding)
        
        // Create semaphore to give a feel of a Synchronous Request via an Async Handler xD
        // CITATION: http://stackoverflow.com/a/34308158/705471
        let syncRequestSemaphore = dispatch_semaphore_create(0)
        var syncResponse: (data: NSData?, response: NSURLResponse?, error: NSError?)? = nil
        
        let asyncTask = syncSession.dataTaskWithRequest(syncRequest, completionHandler: {(data: NSData?, response: NSURLResponse?, error: NSError?) -> () in
            syncResponse = (data, response, error)
            // Release the semaphore
            dispatch_semaphore_signal(syncRequestSemaphore)
        })
        asyncTask.resume() // Start the task now
        
        // But wait for the request to finish and read the response
        dispatch_semaphore_wait(syncRequestSemaphore, DISPATCH_TIME_FOREVER)
        
        // Check the response now
        if( syncResponse?.error != nil ) {
            // Too bad
            toReturn["status"] = "not_possible_request_error"
            // Return
            return toReturn
        }
        
        // Else, try processing the response
        do {
            
            let jsonResponse: [String: AnyObject] = try (NSJSONSerialization.JSONObjectWithData(syncResponse!.data!, options: NSJSONReadingOptions()) as? [String: AnyObject])!
            // Now process the response
            let status = jsonResponse["status"]
            
            if( status == nil ) {
                // We've got an error
                toReturn["status"] = "invalid_json"
                return toReturn
            }
            
            let strStatus: String! = status as! String
            
            if( strStatus == "not_renewed" ) {
                
                let reason: String! = jsonResponse["reason"] as! String
                if( reason == "not_needed" ) {
                    // Token renewal was NOT needed
                    toReturn["status"] = "no_renewal"
                    toReturn["reason"] = "not_needed"
                    return toReturn
                } else if( reason == "no_match" ) {
                    // Token couldn't be renewed as we've got invalid user credentials
                    toReturn["status"] = "no_renewal"
                    toReturn["reason"] = "invalid_cred"
                    return toReturn
                } else if( reason == "failed" ) {
                    // Token couldn't be renewed due to some backend issues
                    toReturn["status"] = "no_renewal"
                    toReturn["reason"] = "backend_failure"
                    return toReturn
                }
                
            } else if( strStatus == "renew_success" ) {
                
                let newLoginToken: String = jsonResponse["new_login_token"] as! String
                let newLoginTokenExpiry: Double! = (jsonResponse["new_token_expiry"] as? NSNumber)?.doubleValue
                
                // Save these in Keychain
                let newLoginTokenSaved: Bool = KeychainWrapper.defaultKeychainWrapper().setString(newLoginToken, forKey: "LocNotes-loginToken")
                let newTokenExpirySaved: Bool = KeychainWrapper.defaultKeychainWrapper().setDouble(newLoginTokenExpiry, forKey: "LocNotes-tokenExpiry")
                // Check Save Results
                if( newLoginTokenSaved && newTokenExpirySaved ) {
                    // New tokens were saved
                    toReturn["status"] = "renewed"
                    return toReturn
                }
                
                // Keycahin failed to store details
                toReturn["status"] = "renewed_but_failed"
                toReturn["reason"] = "keychain_failed"
                return toReturn
                
            }
            
        } catch {
            toReturn["status"] = "invalid_non_json_response"
            return toReturn
        }
        
        // Where did we reach?
        return nil
    }
    
}