//
//  PhotoView.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/8/16.
//  Copyright © 2016 axe. All rights reserved.
//

import Photos
import UIKit

class PhotoView {
    
    // Holds the UIImage that is shown as the thumbnail
    var thumbnailImage: UIImage?
    // Holds the UIImage that it is actually holding
    var realImage: UIImage?
    // Holds the assets for the location of the UIImage
    var assetsLocation: NSURL?
    // Holds the PHAsset itself
    var photoAsset: PHAsset?
    // Holds the location the photo was taken
    var photoLocation: CLLocation?
    // Index of photo view in the CollectionView
    var photoViewIndex: Int! = -1
    // Unique Amazon S3 ID for this PhotoView
    var uniqueS3ID: String?
    // Amazon S3 Link for this PhotoView
    var amazonS3link: String?
    
}