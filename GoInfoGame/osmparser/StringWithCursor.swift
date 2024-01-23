//
//  StringWithCursor.swift
//  QParser
//
//  Created by Naresh Devalapally on 12/30/23.
//

//
//  StringWithCursor.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 12/29/23.
//

import Foundation
public class StringWithCursor : CustomStringConvertible {
     var stringValue: String
     public var cursorIndex: String.Index
    
    public init(stringValue: String) {
        self.stringValue = stringValue
        self.cursorIndex = stringValue.startIndex
    }
     // Better write a subscript than this
    public func get(index:Int) ->  Character? {
        let theIndex = stringValue.index(stringValue.startIndex,offsetBy: index)
        if theIndex < stringValue.endIndex {
            return stringValue[theIndex]
        } else {
            return nil
        }
    }
   public func get(index:String.Index) -> Character? {
        if index < stringValue.endIndex{
            return stringValue[index]
        }else {
            return nil
        }
    }
    
   public func nextIsAndAdvance(str: String) -> Bool {
        if(!nextIs(str: str)) {return false}
            let _ = advanceBy(x: str.count)
            return true
    }
    
  public  func nextIsAndAdvance(c: Character) -> Bool {
        if (!nextIs(c: c)) {return false}
        let _ = advance() // avoid warning for unused stuff
        return true
    }
    
    public func nextMatchesAndAdvance(regex: String) -> Regex<AnyRegexOutput>.Match?{
        let result  = nextMatches(regex: regex)
        if(result == nil) {
            return nil
        }
        // Get the distance to move
        let distanceToMove = stringValue.distance(from: result!.range.lowerBound, to: result!.range.upperBound)
        let _ = advanceBy(x:distanceToMove)
        return result
    }
    
    // Returns if the given string lies ahead/Users/nareshd/Downloads/outputCode.txt
   public func nextIs(str:String) -> Bool {
       return  stringValue[self.cursorIndex...].starts(with: str)
    }
    public func nextIs(c: Character) -> Bool{
        return c == get(index: self.cursorIndex)
    }
    
    public func findNext(str: String, offset: Int = 0) -> Int {
        let newCursorPosition = stringValue.index(cursorIndex, offsetBy: offset)
        let range = stringValue.range(of: str, options: [], range: newCursorPosition..<stringValue.endIndex)
        return toDelta(index: range?.lowerBound)
        
    }
    
    public func findNext(c: Character, offset: Int = 0) -> Int {
        let newCursorPosition = stringValue.index(cursorIndex, offsetBy: offset)
        let theIndex = stringValue[newCursorPosition...].firstIndex(of: c)
        return toDelta(index: theIndex)
    }
    
    public func findNext(regex: String, offset:Int = 0 ) -> Int {
        let newCursorPosition = stringValue.index(cursorIndex, offsetBy: offset)
        let theRegex = try! Regex(regex)
        let range = stringValue[newCursorPosition...].firstMatch(of: theRegex)
        return toDelta(index: range?.range.lowerBound)
    }
    
    
    // Function that tests if the next part of the string matches
    // with the regex
    public func nextMatches(regex: String ) ->  Regex<AnyRegexOutput>.Match? {
        let expression = try! Regex(regex)
        return stringValue[self.cursorIndex...].prefixMatch(of: expression)
    }
    // To be written
    public func toDelta(index: String.Index? ) -> Int {
       if (index == nil ){
           // Return the
           return  stringValue.distance(from: cursorIndex , to: stringValue.endIndex)
       }
       return stringValue.distance(from: cursorIndex, to: index!)
    }
    
    
    
    public func retreatBy(x:Int) {
        let newIndex = stringValue.index(cursorIndex, offsetBy: -x, limitedBy: stringValue.startIndex)
        cursorIndex = newIndex ?? stringValue.startIndex
    }
    
    public func advanceBy(x:Int) -> String {
        let newIndex = stringValue.index(cursorIndex, offsetBy: x, limitedBy: stringValue.endIndex) ?? stringValue.endIndex
        let advancedString = String(stringValue[cursorIndex..<newIndex])
        cursorIndex = newIndex
        return  advancedString
    }
    
    public func isAtEnd(offset: Int = 0) -> Bool {
        let index = stringValue.index(cursorIndex, offsetBy: offset)
        return index == stringValue.endIndex
    }
    
    public func advance()-> Character? {
        if (!isAtEnd()) {
            let result = stringValue[cursorIndex]
            cursorIndex = stringValue.index(cursorIndex, offsetBy: 1)
            return result
        }
        else {
            return nil // TODO: throw something here.
        }
    }
    public var description: String{
        stringValue.prefix(upTo: cursorIndex)+"▶"+stringValue.suffix(from: cursorIndex)
    }
}

