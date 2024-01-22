//
//  Matchers.swift
//  QParser
//
//  Created by Naresh Devalapally on 1/2/24.
//

import Foundation

open class StringMatcher: Matcher<String> {
//    public typealias T = String
    
    open override func matches(obj: String) -> Bool {
        // To write code.
        return true 
    }
    public override init() { // Useless
        
    }
}

//public struct GenericMatcher: Matcher{
//    public typealias T = <#type#>
//    
//    
//}
