//
//  RelativeDate.swift
//  QParser
//
//  Created by Naresh Devalapally on 1/4/24.
//

import Foundation

public protocol DateFilter : CustomStringConvertible {
    var date: Date {get}
}

public class RelativeDate : DateFilter {
    let deltaDays: Float
    init(deltaDays: Float) {
        self.deltaDays = deltaDays
    }
    public var date: Date {
        let now = Date()
        let hourOffset = Double((deltaDays*24.0*3600).rounded())
        let relativeDate = now.addingTimeInterval(hourOffset)
        return relativeDate
    }
    
   public var description: String {
        "\(deltaDays) days"
    }
}

public class FixedDate : DateFilter {
    let theDate: Date
    init(theDate: Date) {
        self.theDate = theDate
    }
    public var date: Date {theDate}
    public var description: String {"\(theDate)"}
    
}


