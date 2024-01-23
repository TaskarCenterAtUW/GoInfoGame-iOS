//
//  ResurveyUtils.swift
//  QParser
//
//  Created by Naresh Devalapally on 1/4/24.
//

import Foundation
// Resurvey utils

//private val OSM_CHECK_DATE_REGEX = Regex("([0-9]{4})-([0-9]{2})(?:-([0-9]{2}))?")

public extension String {
     func toCheckDate() -> Date? {
            let regex =  #/(?<year>[0-9]{4})-(?<month>[0-9]{2})(?:-(?<day>[0-9]{2}))?/#
            guard  let groups = self.wholeMatch(of: regex)
            else {
                return nil
            }
            let df = DateFormatter()
            if let _ = groups.day{
                df.dateFormat = "yyyy-MM-dd"
                return df.date(from: self)
            } else {
                df.dateFormat = "yyyy-MM"
                return df.date(from: self)
            }
        
    }
}



public class ResurveyUtils {
    
    static func getLastCheckDateKeys(key: String) -> [String] {
        
        return [
            "\(key):check_date",
            "check_date:\(key)",
            "\(key):lastcheck",
            "lastcheck:\(key)",
            "\(key):last_checked",
            "last_checked:\(key)"
        ]
        
    }
}
