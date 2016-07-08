//
//  AddNewPhotoCollectionViewCell.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/8/16.
//  Copyright © 2016 axe. All rights reserved.
//

import UIKit

class AddNewPhotoCollectionViewCell: UICollectionViewCell {
    
    // Functions that will be called when the add photo button is clicked
    var addPhotoButtonClickedFunction: ((sender: AnyObject) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame) // Let the super do its job
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder) // Let the super do its job
    }
    
    // MARK: - Actions handled here
    @IBAction func addPhotoButtonClicked(sender: AnyObject) {
        if( addPhotoButtonClickedFunction != nil ) {
            addPhotoButtonClickedFunction!(sender: sender) // Call the function
        }
    }
}