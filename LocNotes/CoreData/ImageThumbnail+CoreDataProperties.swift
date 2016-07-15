//
//  ImageThumbnail+CoreDataProperties.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/11/16.
//  Copyright © 2016 axe. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ImageThumbnail {

    @NSManaged var respectiveLogID: String?
    @NSManaged var fullResS3id: String?
    @NSManaged var image: NSData?

}
