//
//  ProgressLoadingScreenView.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/7/16.
//  Copyright © 2016 axe. All rights reserved.
//

import UIKit

class ProgressLoadingScreenView: UIView {

    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var pageViewHolder: UIView!
    @IBOutlet weak var loadingProgressIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingProgressBar: UIProgressView!
    @IBOutlet weak var loadingProgressLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame) // Let the super do its job
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder) // Let the super do its job
    }

}
