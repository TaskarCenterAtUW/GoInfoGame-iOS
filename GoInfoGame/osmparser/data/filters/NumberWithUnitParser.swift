//
//  NumberWithUnitParser.swift
//  QParser
//
//  Created by Naresh Devalapally on 1/4/24.
//

import Foundation

public extension String {
    
    private static let withUnitRegex = try! Regex("([0-9]+|[0-9]*\\.[0-9]+)\\s*([a-z/'\"]+)")
    private static let feetInchRegex = try! Regex("([0-9]+)\\s*(?:'|ft)\\s*([0-9]+)\\s*(?:\"|in)")
    private static let escapedQuoteRegex = try!  Regex("\\\\(['\"])")
    
     // TODO: Improve this function
     func withOptionalUnitToDoubleOrNull() -> Double? {
         
        if(isEmpty) { return nil } // String is empty
        
        if(!first!.isWholeNumber && first != ".") {return nil}
        if(!last!.isLetter && last != "\"" && last != "\'") {return Double(self)}
        
        //
        do {
            if let withUnitResult = try String.withUnitRegex.wholeMatch(in: self) {
                guard
                    let value = Double(self[withUnitResult[1].range!]),
                    let lastRange = withUnitResult.last?.range
                else{
                    return nil
                }
                let unit = String(self[lastRange])
                if let factor = toStandardFactor(unit: unit) {
                    return value*factor
                }
                else {
                    return nil
                }
                
            } else {
                if let feetInchResult = try String.feetInchRegex.wholeMatch(in: self) {
                    guard
                    let feet = Double(self[feetInchResult[1].range!]),
                    let inches = Double(self[feetInchResult.last!.range!]),
                    let feetFactor = toStandardFactor(unit: "ft"),
                    let inchFactor = toStandardFactor(unit: "in")
                    else {
                        return nil
                    }
                    return feetFactor * feet + inchFactor*inches
                }
                else{
                    return nil
                }
            }
            
        } catch let e {
            return nil
        }
        
        
    }
    
    func stripAndUnescapeQuotes() -> String {
        //TODO:  Implementation to be done.
        var trimmed = self
        if(starts(with: "\'") || starts(with: "\"")) {
            trimmed = String(self.dropFirst().dropLast())
        }
        // Not sure how to do this
//        trimmed.replace(escapedQuoteRegex) {  $0.first?.value
//        }
        return trimmed
    }
    
    
    private func toStandardFactor(unit:String?) -> Double? {
        if(unit == nil) {return nil}
        switch(unit){
        case "km/h","kph":
            return 1.0
        case "mph": return 1.609344
        case "m": return 1.0
        case "mm": return 0.001
        case "cm": return 0.01
        case "km": return 1000.0
        case "ft", "'": return 0.3048
        case "in","\"" : return 0.0254
        case "yd","yds": return 0.9144
        case "t": return 1.0
        case "kg": return 0.001
        case "st": return 0.90718474
        case "lt": return 1.0160469
        case "lb", "lbs": return 0.00045359237
        case "cwt": return 0.05080234544
            
            
        default: return nil
        }
    }
}
