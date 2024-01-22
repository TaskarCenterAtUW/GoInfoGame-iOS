//
//  RegexOrSet.swift
//  QParser
//
//  Created by Naresh Devalapally on 1/3/24.
//

import Foundation

public class RegexOrSet {
    
    func matches(str: String)  -> Bool {
        return false // default implementation
//        fatalError("To be implemented by derived classes")
    }
    
    static let anyRegexStufffExceptPipe = /[.\\[\\]{}()<>*+-=!?^$]/
    
    static func from(string: String) -> RegexOrSet {
        if (!string.contains(anyRegexStufffExceptPipe)){
            let separates = string.split(separator: "|").map{String($0)}
            let theSet = Set(separates)
            return SetRegex(set: theSet)
        }
        else {
//            let regex = try! Regex<Substring>(string)
            
            return RealRegex(regexString:string)
        }
    }
    
}

public class SetRegex : RegexOrSet {
    let set: Set<String>
    
    init(set: Set<String>) {
        self.set = set
    }
    override func matches(str: String)  -> Bool {
        return set.contains(str)
    }
}

public class RealRegex : RegexOrSet {
    let regexString : String
    init(regexString: String) {
        self.regexString = regexString
    }
    override func matches(str: String) -> Bool {
        do {
            let regex = try Regex(self.regexString)
            if let m = try  regex.wholeMatch(in: str) {
                return true
            } else {
                return false
            }
        } catch let e {
            return false
        }
    }
}
