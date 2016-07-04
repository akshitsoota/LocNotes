//
//  CommonUtils.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/2/16.
//  Copyright © 2016 axe. All rights reserved.
//

import UIKit

class CommonUtils {
    
    static func returnLoadingBlurredView(target: UIViewController) -> (UIView?) {
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            // Create the blur effect
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            // Fill the view
            blurEffectView.frame = target.view.bounds
            blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            // Add the ActivityIndicator
            let activitySpinner: UIActivityIndicatorView! = UIActivityIndicatorView.init(activityIndicatorStyle: .WhiteLarge)
            activitySpinner.center = CGPoint(x: UIScreen.mainScreen().bounds.width / 2.0, y: UIScreen.mainScreen().bounds.height / 2.0)
            activitySpinner.startAnimating()
            
            blurEffectView.addSubview(activitySpinner)
            
            // Finally, return what we were called for
            return blurEffectView
        }
        
        // Cannot return the blurred view
        return nil
    }
    
}