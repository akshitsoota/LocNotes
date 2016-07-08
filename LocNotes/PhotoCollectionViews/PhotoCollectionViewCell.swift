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
            if( _extraInfo != nil && _extraInfo!.image != nil ) {
                _updateImage(_extraInfo!.image!)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame) // Let the super do its job
        // Setup view
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder) // Let the super do its job
        // Setup view
        setupView()
    }
    
    // MARK: - View setup here
    func setupView() {
        let imageTapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PhotoCollectionViewCell.photoImageClicked))
        // TODO:
        if( self.imageView != nil ) {
            self.imageView.addGestureRecognizer(imageTapGestureRecognizer)
        }
    }
    
    private func _updateImage(image: UIImage) {
        self.imageView.image = image
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