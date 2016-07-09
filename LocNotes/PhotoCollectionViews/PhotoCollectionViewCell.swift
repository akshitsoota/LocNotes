//
//  PhotoCollectionViewCell.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/8/16.
//  Copyright © 2016 axe. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    // Function that will be called when the image view is tapped
    var imageViewClickedFunction: ((sender: AnyObject, extraInfo: PhotoView?) -> Void)?
    // Function that will be called when the remove photo button is tapped
    var removePhotoButtonClickedFunction: ((sender: AnyObject, extraInfo: PhotoView?) -> Void)?
    // Extra information that will be passed along with any function call
    private var _extraInfo: PhotoView?
    var extraInformation: PhotoView? {
        get { return _extraInfo }
        set {
            _extraInfo = newValue
            // Now update the UI with the thumbnail
            if( _extraInfo != nil && _extraInfo!.thumbnailImage != nil ) {
                _updateThumbnailImage(_extraInfo!.thumbnailImage!)
            }
        }
    }
    // Holds if the view was setup by adding a tap gesture recognizer on the ImageView
    var viewSetup: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame) // Let the super do its job
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder) // Let the super do its job
    }
    
    private func _updateThumbnailImage(thumbnailImage: UIImage) {
        self.imageView.image = thumbnailImage
        // Setup the view if it wasn't setup earlier
        if( !viewSetup ) {
            // Setup the TapGestureRecognizer
            let imageTapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PhotoCollectionViewCell.photoImageClicked))
            self.imageView.addGestureRecognizer(imageTapGestureRecognizer)
            // We've setup the view so:
            viewSetup = true
        }
    }
    
    // MARK: - Actions handled here
    @IBAction func removePhotoButtonClicked(sender: AnyObject) {
        if( removePhotoButtonClickedFunction != nil ) {
            removePhotoButtonClickedFunction!(sender: sender, extraInfo: _extraInfo) // Call the function
        }
    }
    
    func photoImageClicked(imageView: AnyObject) {
        if( imageViewClickedFunction != nil ) {
            imageViewClickedFunction!(sender: imageView, extraInfo: _extraInfo) // Call the function
        }
    }
}