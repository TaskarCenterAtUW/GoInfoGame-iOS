//
//  TestBooleanExpressionParser.swift
//  QParserTests
//
//  Created by Naresh Devalapally on 1/2/24.
//

import Foundation

@testable import osmparser
class TestBooleanExpressionParser {
    static let shared = TestBooleanExpressionParser()
    
    private init() {
//        BooleanExpression
//        BooleanExpression<Matcher<String> , String> 
    }
    func parse(input:String ) throws -> BooleanExpression<StringMatcher, String>? {
        let builder = BooleanExpressionBuilder<StringMatcher, String>()
        let reader = StringWithCursor(stringValue: input)
        while (!reader.isAtEnd()){
            if (reader.nextIsAndAdvance(c: "*")) {
                
                builder.addAnd()
            }
            else if(reader.nextIsAndAdvance(c: "+")){
                
                builder.addOr()
            }
            else if(reader.nextIsAndAdvance(c: "(")){
                builder.addOpenBracket()
            }
           else  if(reader.nextIsAndAdvance(c: ")")){
              try  builder.addCloseBracket()
            }
            else {
                if let character = reader.advance() {
                    
                    builder.addValue(i: TestBooleanExpressionValue(value: String(character)))
                }
            }
            
        }
//        print(builder)
        return try builder.build()
        
    }
}
