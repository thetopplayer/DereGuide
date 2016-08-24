//
//  BirthdayCenter.swift
//  CGSSGuide
//
//  Created by zzk on 16/8/16.
//  Copyright © 2016年 zzk. All rights reserved.
//

import UIKit

class BirthdayCenter: NSObject {
    static let defaultCenter = BirthdayCenter()
    var sortedChars: [CGSSChar]!
    private override init() {
        super.init()
        let dao = CGSSDAO.sharedDAO
        sortedChars = dao.charDict.allValues as! [CGSSChar]
        sortInside()
    }
    
    var tempChar: CGSSChar!
    var indexOfTempChar: Int? {
        if tempChar == nil {
            return nil
        } else {
            return sortedChars.indexOf(tempChar)
        }
    }
    
    func sortInside() {
        if let index = indexOfTempChar {
            sortedChars.removeAtIndex(index)
        }
        tempChar = CGSSChar()
        let nowComp = getNowDateComponents()
        tempChar.birthDay = nowComp.day
        tempChar.birthMonth = nowComp.month
        sortedChars.append(tempChar)
        sortedChars.sortInPlace({ (char1, char2) -> Bool in
            if char1.birthMonth > char2.birthMonth {
                return false
            } else if char1.birthMonth == char2.birthMonth && char1.birthDay > char2.birthDay {
                return false
            } else if char1.birthMonth == char2.birthMonth && char1.birthDay == char2.birthDay && char2 == tempChar {
                return false
            } else {
                return true
            }
        })
    }
    
    func scheduleNotifications() {
        self.removeNotification()
        dispatch_async(dispatch_get_global_queue(0, 0)) {
            for char in self.getRecent(1, endDays: 30) {
                let localNotification = UILocalNotification()
                localNotification.fireDate = self.getNextBirthday(char)
                localNotification.alertBody = "今天是\(char.name!)的生日(\(char.birthMonth!)月\(char.birthDay!)日)"
                localNotification.category = "Birthday"
                UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
            }
        }
    }
    
    func getRecent(startDays: Int, endDays: Int) -> [CGSSChar] {
        let timeZone = NSUserDefaults.standardUserDefaults().birthdayTimeZone
        let gregorian = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        gregorian?.timeZone = timeZone
        var arr = [CGSSChar]()
        var index = indexOfTempChar!
        while true {
            index += 1
            if index >= sortedChars.count {
                index = 0
            }
            if sortedChars[index] == tempChar {
                break
            }
            let newdate = getNowDateTruncateHours()
            let date = getNextBirthday(sortedChars[index])
            let result = gregorian!.components(NSCalendarUnit.Day, fromDate: newdate!, toDate: date, options: NSCalendarOptions(rawValue: 0))
            if result.day < startDays {
                continue
            } else if result.day >= startDays && result.day <= endDays {
                arr.append(sortedChars[index])
            } else {
                break
            }
        }
        return arr
    }
    
    func getNowDateComponents() -> NSDateComponents {
        let nowDate = NSDate()
        let timeZone = NSUserDefaults.standardUserDefaults().birthdayTimeZone
        let gregorian = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        gregorian?.timeZone = timeZone
        let nowComp = gregorian!.components(NSCalendarUnit.init(rawValue: NSCalendarUnit.Year.rawValue | NSCalendarUnit.Month.rawValue | NSCalendarUnit.Day.rawValue), fromDate: nowDate)
        return nowComp
    }
    
    func getNowDateTruncateHours() -> NSDate? {
        let nowComp = getNowDateComponents()
        let gregorian = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        gregorian?.timeZone = NSUserDefaults.standardUserDefaults().birthdayTimeZone
        return gregorian?.dateFromComponents(nowComp)
    }
    
    func getNextBirthday(char: CGSSChar) -> NSDate {
        
        let nowComp = getNowDateComponents()
        let dateformatter = NSDateFormatter()
        dateformatter.dateFormat = "yyyyMMdd"
        dateformatter.timeZone = NSUserDefaults.standardUserDefaults().birthdayTimeZone
        let dateString: String
        if nowComp.month > char.birthMonth! || (nowComp.month == char.birthMonth! && nowComp.day > char.birthDay!) {
            dateString = String.init(format: "%04d%02d%02d", nowComp.year + 1, char.birthMonth!, char.birthDay!)
        } else {
            dateString = String.init(format: "%04d%02d%02d", nowComp.year, char.birthMonth!, char.birthDay!)
        }
        let date = dateformatter.dateFromString(dateString)
        return date!
    }
    
    func removeNotification() {
        dispatch_async(dispatch_get_global_queue(0, 0)) {
            if let notifications = UIApplication.sharedApplication().scheduledLocalNotifications {
                for notification in notifications {
                    if notification.category == "Birthday" {
                        UIApplication.sharedApplication().cancelLocalNotification(notification)
                    }
                }
            }
        }
    }
}
