//
//  StringWithCursor.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 12/29/23.
//

import Foundation
class StringWithCursor{
    var stringValue: String
    var cursorIndex: String.Index
    
    init(stringValue: String) {
        self.stringValue = stringValue
        self.cursorIndex = stringValue.startIndex
    }
     // Better write a subscript than this
     func get(index:Int) ->  Character? {
        let theIndex = stringValue.index(stringValue.startIndex,offsetBy: index)
        if theIndex < stringValue.endIndex {
            return stringValue[theIndex]
        } else {
            return nil
        }
    }
    func get(index:String.Index) -> Character? {
        if index < stringValue.endIndex{
            return stringValue[index]
        }else {
            return nil
        }
    }
    
    // Returns if the given string lies ahead/Users/nareshd/Downloads/outputCode.txt
    func nextIs(str:String) -> Bool {
        return  stringValue[self.cursorIndex...].starts(with: str)
    }
    func nextIs(c: Character) -> Bool{
        return c == get(index: self.cursorIndex)
    }
    // Function that tests if the next part of the string matches
    // with the regex
    func nextMatches(regex: String) {
        
    }
    // To be written
    func toDelta(index: Int ) -> Int {
        return -1
    }
    
    func retreatBy(x:Int) {
        let newIndex = stringValue.index(cursorIndex, offsetBy: -x, limitedBy: stringValue.startIndex)
        cursorIndex = newIndex ?? stringValue.startIndex
    }
    
    func advanceBy(x:Int) -> String {
        let newIndex = stringValue.index(cursorIndex, offsetBy: x)
        return String(stringValue[cursorIndex...newIndex])
    }
    
    func isAtEnd(offset: Int = 0) -> Bool {
        let index = stringValue.index(cursorIndex, offsetBy: offset)
        return index == stringValue.endIndex
    }
    
    func advance()-> Character? {
        if (!isAtEnd()) {
            let result = stringValue[cursorIndex]
            cursorIndex = stringValue.index(cursorIndex, offsetBy: 1)
            return result
        }
        else {
            return nil // TODO: throw something here.
        }
    }
}
