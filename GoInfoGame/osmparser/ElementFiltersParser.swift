//
//  ElementFiltersParser.swift
//  QParser
//
//  Created by Naresh Devalapally on 12/31/23.
//

import Foundation
public enum ElementsTypeFilter: CaseIterable {
    case NODES
    case WAYS
    case RELATIONS
    func osmValue() -> String {
        switch self {
        case .NODES:
            return "nodes"
        case .RELATIONS:
            return "relations"
        case .WAYS:
            return "ways"
        }
    }
    func osmQValue() -> String {
        switch self {
        case .NODES : return "node"
        case .RELATIONS : return "rel"
        case .WAYS: return "way"
        }
    }
}

public class ElementFiltersParser:StringWithCursor {
    
    private enum ReservedWords : String {
        case with = "with"
        case or = "or"
        case and = "and"
    }
    
    private enum QuotationMarks : Character, CaseIterable {
        case quote = "'"
        case doubleQuote = "\""
    }
    private enum Operators: String, CaseIterable {
        case greaterOrEqualThan = ">="
        case lessOrEqualThan = "<="
        case greaterThan = ">"
        case lessThan = "<"
        case notEquals = "!="
        case equals = "="
        case notLike = "!~"
        case like = "~"
        case older = "older"
        case newer = "newer"
    }
    private enum TimeOperators : String , CaseIterable {
        case today = "today"
        case older = "older"
        case newer = "newer"
    }
    
    private enum KeyOperators: String, CaseIterable {
        case equals = "="
        case notEquals = "!="
        case like = "~"
        case notLike = "!~"
        
        static func contains(str:String) -> Bool{
            return KeyOperators(rawValue: str) != nil
        }
    }
    private enum ComparisonOperators: String, CaseIterable {
        case greaterThan = ">"
        case greaterOrEqualThan = ">="
        case lessThan = "<"
        case lessOrEqualThan = "<="
        
        static func contains(str:String) -> Bool {
            return ComparisonOperators(rawValue: str) != nil
        }
    }
    
    private enum TimeConstants: String, CaseIterable {
        case years = "years"
        case months = "months"
        case weeks = "weeks"
        case days = "days"
    }
    
    
    
    private let WHITESPACES_REGEX = "\\s*"
    private let WHITESPACE_REGEX = "\\s"
    private let RESERVED_WORDS: [String] = [ReservedWords.with.rawValue, ReservedWords.or.rawValue, ReservedWords.and.rawValue]
    private let NUMBER_WITH_OPTIONAL_UNIT_REGEX = "[0-9]+'[0-9]+\"|(?:[0-9]*\\.[0-9]+|[0-9]+)[a-z/'\"]*"
    private let NOT_WITH_WHITESPACE_AND_OPENING_BRACE = "!\\s*\\("
    private let NOT = "!"
    
    func expectAnyNumberOfSpaces() -> Int {
       let result =   nextMatchesAndAdvance(regex: WHITESPACES_REGEX)
        if let range = result?.range {
            return stringValue.distance(from: range.lowerBound, to: range.upperBound)
        }
        return  0 // Not sure though.
    }
    
    func expectOneOrMoreSpaces() -> Int {
        let result =   nextMatchesAndAdvance(regex: WHITESPACE_REGEX)
        if(result == nil){
            return -1
        }
        else {
            return expectAnyNumberOfSpaces() + 1
        }
    }
    
    func nextIsReservedWord() -> String? {
        let wordLength = findWordLength()
        return RESERVED_WORDS.first { ele in
            nextIs(str: ele) && wordLength == ele.count
        }
    }
    
    func findWordLength() -> Int {
        return min(findNext(regex: WHITESPACE_REGEX),findNext(c: ")"))
    }
    
    func parseElementDeclaration() throws -> ElementsTypeFilter  {
        let _ =  expectAnyNumberOfSpaces()
        for filterType in ElementsTypeFilter.allCases {
            if(nextIsAndAdvance(str: filterType.osmValue())){
             let _ =    expectAnyNumberOfSpaces()
                return filterType
            }
        }
        // Throw parsing exception
        throw ParseException("Expected element types. Any of: nodes, ways or relations, separated by ','")
    }
    
    func parseElementsDeclaration() throws -> Set<ElementsTypeFilter> {
        var result: Set<ElementsTypeFilter> = []
        repeat {
            let element = try parseElementDeclaration()
            if(result.contains(element)){
                throw ParseException("Mentioned the same element type twice")
            }
            result.insert(element)
        } while (nextIsAndAdvance(c: ","))
        
        return result
    }
    
    func parseTags() throws -> BooleanExpression<ElementFilter, Element>? {
        if (!nextIsAndAdvance(str: ReservedWords.with.rawValue)){
            if(!isAtEnd()){
                throw ParseException("Expected end of string or 'with' keyword")
            }
            return nil
        }
        
        let builder = BooleanExpressionBuilder<ElementFilter, Element>()
        
        repeat {
            // Need to break
            if ( try !parseBracketsAndSpaces(bracket: "(", expr: builder)){
                throw ParseException("Expected a whitespace or bracket before the tag")
            }
            if (nextMatches(regex: NOT_WITH_WHITESPACE_AND_OPENING_BRACE) != nil ){
                advanceBy(x:NOT.count)
                builder.addNot()
                continue
            }
            builder.addValue(i: try parseTag())
            let separated = try parseBracketsAndSpaces(bracket: ")", expr: builder)
            if (isAtEnd()) {break}
            if(!separated){
                throw ParseException("Expected a whitespace or bracket after the tag")
            }
            if (nextIsAndAdvance(str: ReservedWords.or.rawValue)){
                builder.addOr()
            } else if (nextIsAndAdvance(str: ReservedWords.and.rawValue)){
                builder.addAnd()
            } else {
                throw ParseException("Expected end of string, 'and' or 'or' ")
            }
             
            
        }while true
        
        // End of loop building
        
        
        // Last one
        do{
            return try builder.build()
        } catch let e {
            throw ParseException("Illegal state exception")
        }
        
    }
    
    func parseTag() throws -> ElementFilter {
        if (nextIsAndAdvance(c: "!")){  //TODO: Change the NOT sign
            if(nextIsAndAdvance(str: Operators.like.rawValue)){
                expectAnyNumberOfSpaces()
                return  NotHasKeyLike(key:try parseKey())
            } else {
                expectAnyNumberOfSpaces()
                return NotHasKey(key: try parseKey())
            }
        }
        
        if(nextIsAndAdvance(str: Operators.like.rawValue)) {
            expectAnyNumberOfSpaces()
            let key = try parseKey()
            let op = parseOperatorWithSurroundingSpaces()
            if (op == nil){
                return HasKeyLike(key: key)
            } else if (Operators.like.rawValue == op!){
                return HasTagLike(key: key, value: try parseQuotableWord())
            } else if (Operators.notLike.rawValue == op!){
                return NotHasTagLike(key: key, value: try parseQuotableWord())
            }
            throw ParseException()
        }
        if(nextIsAndAdvance(str: Operators.older.rawValue)){
            expectOneOrMoreSpaces()
            return ElementOlderThan(dateFilter: try parseDate())
        }
        if(nextIsAndAdvance(str: Operators.newer.rawValue)){
            expectOneOrMoreSpaces()
            return ElementNewerThan(dateFilter: try parseDate())
        }
        let key = try parseKey()
        let op = parseOperatorWithSurroundingSpaces()
        if(op == nil){
            return HasKey(key: key)
        }
        if (op! == Operators.older.rawValue ){
            return CombineFilters(filters: [HasKey(key: key), TagOlderThan(key: key, dateFilter: try parseDate())])
        }
        if(op! == Operators.newer.rawValue){
            return CombineFilters(filters: [HasKey(key: key), TagNewerThan(key: key, dateFilter: try parseDate())])
        }
        // Change the code here.
        if (KeyOperators.contains(str: op!)){
            let value = try parseQuotableWord()
            if op! == KeyOperators.equals.rawValue {
                return HasTag(key: key, value: value)
            }
            else if op! == KeyOperators.notEquals.rawValue {
                return NotHasTag(key: key, value: value)
                
            } else if op! == KeyOperators.like.rawValue {
                return HasTagValueLike(key: key, value: value)
            } else if op! == KeyOperators.notLike.rawValue {
                return NotHasTagValueLike(key: key, value: value)
            }
            
        }
        
        if(ComparisonOperators.contains(str: op!)) {
            let numberWithUnit = nextMatchesAndString(regex: NUMBER_WITH_OPTIONAL_UNIT_REGEX) // nextMatches(regex:NUMBER_WITH_OPTIONAL_UNIT_REGEX)?[0].value as? String
            // Need to get this value
            if(numberWithUnit != nil && findWordLength() == numberWithUnit!.count){
                advanceBy(x: numberWithUnit!.count)
               guard let doubleV = numberWithUnit!.withOptionalUnitToDoubleOrNull()
                else {
                    throw ParseException()
                }
                let value = Float(doubleV)
                if(op! == Operators.greaterThan.rawValue) { return HasTagGreaterThan(key: key, value: value)}
                if(op! == Operators.greaterOrEqualThan.rawValue) {return HasTagGreaterOrEqualThan(key: key, value: value)}
                if(op! == Operators.lessThan.rawValue) {return HasTagLessThan(key: key, value: value)}
                if(op! == Operators.lessOrEqualThan.rawValue) {return HasTagLessOrEqualThan(key: key, value: value)}
                
                
            } else {
                let value = try parseDate()
                if (op! == Operators.greaterThan.rawValue) { return HasDateTagGreaterThan(key: key, dateFilter: value)}
                if (op! == Operators.greaterOrEqualThan.rawValue) { return HasDateTagGreaterOrEqualThan(key: key, dateFilter: value)}
                if (op! == Operators.lessThan.rawValue) { return HasDateTagLessThan(key: key, dateFilter: value)}
                if (op! == Operators.lessOrEqualThan.rawValue) { return HasDateTagLessOrEqualThan(key: key, dateFilter: value)}
            }
            
            throw ParseException()
        }
        
        throw ParseException()
        
    }
    
    func parseDate() throws -> DateFilter {
        let length = findWordLength()
        if (length == 0){
            throw ParseException()
        }
        let word = advanceBy(x: length)
        if word == TimeOperators.today.rawValue {
            var deltaDays: Float = 0
            if(nextMatchesAndAdvance(regex: WHITESPACES_REGEX) != nil){
                expectAnyNumberOfSpaces()
                deltaDays = try parseDurationInDays()
            }
            return RelativeDate(deltaDays: deltaDays)
        }
        let date = word.toCheckDate()
        if (date != nil){
            return FixedDate(theDate: date!)
        }
        throw ParseException()
    }
    
    func parseDeltaDurationInDays() throws -> Float {
        do {
            if (nextIsAndAdvance(c: "+")) {
                expectAnyNumberOfSpaces()
                return try parseDurationInDays()
            }
            else if (nextIsAndAdvance(c: "-")){
                expectAnyNumberOfSpaces()
                return try -parseDurationInDays()
            }
            else {
                throw ParseException()
            }
        } catch {
            throw ParseException()
        }
    }
    func parseDurationInDays() throws -> Float {
        do {
            let duration = try parseNumber()
            expectOneOrMoreSpaces()
            if(nextIsAndAdvance(str: TimeConstants.years.rawValue)){
                return 365.25*duration
            }
            else if (nextIsAndAdvance(str: TimeConstants.months.rawValue)){
                return 30.5*duration
            } else if (nextIsAndAdvance(str: TimeConstants.weeks.rawValue)){
                return 7*duration
            }else if (nextIsAndAdvance(str: TimeConstants.days.rawValue)) {
                return duration
            }
            else {
                throw ParseException()
            }
        }catch {
            throw ParseException()
        }
        
    }
    
    func parseNumber() throws ->  Float {
        do {
            let word = try parseWord()
            return Float(word)!
        } catch  {
            throw ParseException()
        }

    }
    
    func parseWord() throws -> String {
        let length = findWordLength()
        if (length == 0){
            throw ParseException()
        }
        return advanceBy(x: length)
    }
    
    // Methods for parseTag implementation
    
    
    private func parseQuotableWord() throws -> String {
        let length = findQuotableWordLength()
        if (length == 0){
            throw ParseException()
        }
        let adWord = advanceBy(x: length)
        return adWord.stripAndUnescapeQuotes()
    }
   
    private func parseOperatorWithSurroundingSpaces() -> String? {
        let spaces = expectAnyNumberOfSpaces()
        if let result = Operators.allCases.first(where: { op in
            nextIsAndAdvance(str: op.rawValue)
        }) {
            expectAnyNumberOfSpaces()
            return result.rawValue
        }
        else {
            retreatBy(x: spaces)
//            expectAnyNumberOfSpaces()
            return nil
        }
    }
    
    private func parseBracketsAndSpaces(bracket : Character, expr: BooleanExpressionBuilder<ElementFilter, Element>) throws -> Bool{
        let initialCursorPos = cursorIndex
        var loopStartCursorPos = cursorIndex
        repeat {
            loopStartCursorPos = cursorIndex
            expectAnyNumberOfSpaces()
            if(nextIsAndAdvance(c: bracket)){
                do {
                    if(bracket == "(") { expr.addOpenBracket()}
                    else if(bracket == ")") {try expr.addCloseBracket()}
                }
                catch {
                    throw ParseException()
                }
                
            }
        } while (loopStartCursorPos < cursorIndex)
        expectAnyNumberOfSpaces()
        
        return initialCursorPos < cursorIndex
    }
    
    private func parseKey() throws -> String {
        if let reserved = nextIsReservedWord() {
            throw ParseException()
        }
        let length = findKeyLength()
        if length == 0 {
            throw ParseException()
        }
        return advanceBy(x: length).stripAndUnescapeQuotes()
    }
    
    private func findKeyLength() -> Int {
        do {
            if let length = try findQuotationLength() {
                return length
            }
            // else
            // Can we make it better
            var length = findWordLength()
            for o in Operators.allCases {
                let opLen = findNext(str: o.rawValue)
                if (opLen < length) { length = opLen}
            }
            return length
            
        } catch let e {
            return 0 // Not sure here.
        }
    
    }
    
    private func findQuotableWordLength()  -> Int {
        try! findQuotationLength() ?? findWordLength()
    }
   
    private func findQuotationLength() throws -> Int?{
        let marks = [QuotationMarks.doubleQuote.rawValue, QuotationMarks.quote.rawValue]
        
        for quota in marks {
            if(nextIs(c: quota)){
                var length = 0
                while (true) {
                    length = findNext(c: quota, offset: 1 + length)
                    if (isAtEnd(offset: length)) {
                        throw ParseException()
                    }
                    // missing ignore escaped
                    let nextIndex = stringValue.index(cursorIndex, offsetBy: length-1)
                    if(get(index: nextIndex) == "\\") {continue}
//                    if (get(cursorPos + length - 1) == '\\') continue
                    return length + 1
                }
            }
        }
        return nil
    }
    
    // additional method written for convenience
    public func nextMatchesAndString(regex:String) -> String? {
        guard let result = nextMatches(regex: regex),
              let firstElement = result.first,
                let range = firstElement.range else {return nil}
        return String(stringValue[range])
    }
}


public extension String {
    func toElementFilterExpression() throws -> ElementFilterExpression {
        let cursor = ElementFiltersParser(stringValue: self)
        return ElementFilterExpression(elementTypes: try cursor.parseElementsDeclaration(), elementExprRoot: try cursor.parseTags())
    }
}
