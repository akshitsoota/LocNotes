//
//  PhotoView.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/8/16.
//  Copyright © 2016 axe. All rights reserved.
//

import UIKit

class PhotoView {
    
    // Holds the UIImage that is held
    var image: UIImage?
    // Index of photo view in the CollectionView
    var photoViewIndex: Int! = -1
    // Unique Amazon S3 ID for this PhotoView
    var uniqueS3ID: String?
    // Amazon S3 Link for this PhotoView
    var amazonS3link: String?
    
}