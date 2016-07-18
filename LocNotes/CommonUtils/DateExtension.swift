//
//  DateExtension.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/18/16.
//  Copyright © 2016 axe. All rights reserved.
//
//  CITATION:
//    http://stackoverflow.com/a/27184261/705471
//  I have made modification to suit my needs

import Foundation

extension NSDate {
    func yearsFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(.Year, fromDate: date, toDate: self, options: []).year
    }
    func monthsFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(.Month, fromDate: date, toDate: self, options: []).month
    }
    func weeksFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(.WeekOfYear, fromDate: date, toDate: self, options: []).weekOfYear
    }
    func daysFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(.Day, fromDate: date, toDate: self, options: []).day
    }
    func hoursFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(.Hour, fromDate: date, toDate: self, options: []).hour
    }
    func minutesFrom(date: NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Minute, fromDate: date, toDate: self, options: []).minute
    }
    func secondsFrom(date: NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Second, fromDate: date, toDate: self, options: []).second
    }
    func offsetFrom(date: NSDate) -> String {
        if yearsFrom(date)   > 0 {
            let value = yearsFrom(date)
            if( value == 1 ) { return "\(value) year ago"    }
            else             { return "\(value) years ago"   }
        }
        if monthsFrom(date)  > 0 {
            let value = monthsFrom(date)
            if( value == 1 ) { return "\(value) month ago"   }
            else             { return "\(value) months ago"  }
        }
        if weeksFrom(date)   > 0 {
            let value = weeksFrom(date)
            if( value == 1 ) { return "\(value) week ago"    }
            else             { return "\(value) weeks ago"   }
        }
        if daysFrom(date)    > 0 {
            let value = daysFrom(date)
            if( value == 1 ) { return "\(value) day ago"     }
            else             { return "\(value) days ago"    }
        }
        if hoursFrom(date)   > 0 {
            let value = hoursFrom(date)
            if( value == 1 ) { return "\(value) hour ago"    }
            else             { return "\(value) hours ago"   }
        }
        if minutesFrom(date) > 0 {
            let value = minutesFrom(date)
            if( value == 1 ) { return "\(value) minute ago"  }
            else             { return "\(value) minutes ago" }
        }
        if secondsFrom(date) > 0 {
            let value = secondsFrom(date)
            if( value == 1 ) { return "\(value) second ago"  }
            else             { return "\(value) seconds ago" }
        }
        // Where have we reached?
        return ""
    }
}