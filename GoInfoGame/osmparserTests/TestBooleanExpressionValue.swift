//
//  TestBooleanExpressionValue.swift
//  QParserTests
//
//  Created by Naresh Devalapally on 1/2/24.
//

import Foundation
//import QParser

@testable import osmparser

public class TestBooleanExpressionValue: StringMatcher, CustomStringConvertible {
    let value: String
    init(value: String) {
        self.value = value
        super.init()
    }
    public override func matches(obj: String) -> Bool {
        obj == value
    }
    public var description: String {
        return value
    }
    
}

//public class TestLeaf<StringMatcher, String> : BooleanExpression<StringMatcher, String> {
//    
//    
//    
//    
//}
