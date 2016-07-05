//
//  CommonUtils.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/2/16.
//  Copyright © 2016 axe. All rights reserved.
//

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
    
}