//
//  LocationLog+CoreDataProperties.swift
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

extension LocationLog {

    @NSManaged var logID: String?
    @NSManaged var logTitle: String?
    @NSManaged var logDesc: String?
    @NSManaged var imageS3ids: String?
    @NSManaged var locationNames: String?
    @NSManaged var locationPoints: String?
    @NSManaged var addedDate: NSNumber?
    @NSManaged var updateDate: NSNumber?

}
