//
//  ElementFilter.swift
//  QParser
//
//  Created by Naresh Devalapally on 1/3/24.
//

import Foundation

public class ElementFilter: Matcher<Element> , CustomStringConvertible{
    public var description: String {
        return ""
    }
}

public class HasKey : ElementFilter {
    
    let key: String
    init(key: String) {
        self.key = key
    }
    
    public override var description: String {
        self.key
    }
    
    override func matches(obj: Element) throws -> Bool {
        obj.tags.keys.contains(self.key)
    }
}

public class NotHasKey : ElementFilter {
    let key: String
    init(key: String) {
        self.key = key
    }
    
    public override var description: String {
        "!\(self.key)"
    }
    
    override func matches(obj: Element) throws -> Bool {
        !obj.tags.keys.contains(self.key)
    }
}

public class HasTag : ElementFilter {
    let key:String
    let value:String
    init(key: String, value: String) {
        self.key = key
        self.value = value
    }
    public override var description: String {
        "\(self.key) = \(self.value)"
    }
    override func matches(obj: Element) throws -> Bool {
        obj.tags[self.key] == self.value
    }
}

public class NotHasTag : ElementFilter {
    let key: String
    let value: String
    init(key: String, value: String) {
        self.key = key
        self.value = value
    }
    public override var description: String {
        "\(self.key) != \(self.value)"
    }
    override func matches(obj: Element) throws -> Bool {
        obj.tags[self.key] != self.value
    }
}

public class HasKeyLike : ElementFilter {
    let regex: RegexOrSet
    let key : String
    init(key: String) {
        self.key = key
        self.regex = RegexOrSet.from(string: key)
    }
    public override var description: String { "~\(self.key)" }
    override func matches(obj: Element) throws -> Bool {
        return obj.tags.keys.contains { self.regex.matches(str: $0) }
    }
}


public class NotHasKeyLike: ElementFilter {
    let regex: RegexOrSet
    let key: String
    
    init(key: String) {
        self.regex = RegexOrSet.from(string: key)
        self.key = key
    }
    
    public override var description: String {
        "!~\(self.key)"
    }
    
    override func matches(obj: Element) throws -> Bool {
        return !obj.tags.keys.contains{ self.regex.matches(str: $0 )}
    }
}

public class HasTagValueLike : ElementFilter {
    let regex: RegexOrSet
    let key: String
    let value: String
    init( key: String, value: String) {
        
        self.key = key
        self.value = value
        self.regex = RegexOrSet.from(string: value)
    }
    override func matches(obj: Element) throws -> Bool {
        if let tagVal = obj.tags[key] {
            return self.regex.matches(str: tagVal)
        } else {
            return false
        }
    }
    
    public override var description: String {
        "\(self.key) ~ \(self.value)"
    }
}

public class NotHasTagValueLike: ElementFilter {
    let regex: RegexOrSet
    let key: String
    let value: String
    init( key: String, value: String) {
        
        self.key = key
        self.value = value
        self.regex = RegexOrSet.from(string: value)
    }
    override func matches(obj: Element) throws -> Bool {
        if let tagVal = obj.tags[key] {
            return !self.regex.matches(str: tagVal)
        } else {
            return true
        }
    }
    
    public override var description: String {
        "\(self.key) !~ \(self.value)"
    }
    
}


public class HasTagLike: ElementFilter {
    private let keyRegex : RegexOrSet
    private let valueRegex: RegexOrSet
    let key: String
    let value: String
    
    init( key: String, value: String) {
        self.key = key
        self.value = value
        self.keyRegex = RegexOrSet.from(string: key)
        self.valueRegex = RegexOrSet.from(string: value)
    }
    public override var description: String{
        "~\(self.key) ~ \(self.value)"
    }
    
    override func matches(obj: Element) throws -> Bool {
        obj.tags.contains { (key: String, value: String) in
            self.keyRegex.matches(str: key) && self.valueRegex.matches(str: value)
        }
    }
}

public class NotHasTagLike : ElementFilter {
    private let keyRegex : RegexOrSet
    private let valueRegex: RegexOrSet
    let key: String
    let value: String
    
    init( key: String, value: String) {
        self.key = key
        self.value = value
        self.keyRegex = RegexOrSet.from(string: key)
        self.valueRegex = RegexOrSet.from(string: value)
    }
    
    public override var description: String {
        "~\(key) !~ \(value)"
    }
    
    override func matches(obj: Element) throws -> Bool {
        if (obj.tags.isEmpty) {return true}
        return obj.tags.contains { (key: String, value: String) in
            !self.keyRegex.matches(str: key) || !self.valueRegex.matches(str: value)
        }
    }
}

public class HasTagLessThan: CompareTagValue {
    public override var description: String {
        "\(key) < \(value)"
    }
    public override func compareTo(tagValue: Float) -> Bool {
        tagValue < value
    }
}
public class HasTagGreaterThan: CompareTagValue {
    public override var description: String {
        "\(key) > \(value)"
    }
    public override func compareTo(tagValue: Float) -> Bool {
        tagValue > value
    }
}



public class HasTagLessOrEqualThan : CompareTagValue {
    public override var description: String {
        "\(key) <= \(value)"
    }
    public override func compareTo(tagValue: Float) -> Bool {
        tagValue <= value
    }
}

public class HasTagGreaterOrEqualThan : CompareTagValue {
    public override var description: String {
        "\(key) >= \(value)"
    }
    public override func compareTo(tagValue: Float) -> Bool {
        tagValue >= value
    }
}


public class CompareTagValue: ElementFilter {
    let key:String
    let value: Float
    init(key: String, value: Float) {
        self.key = key
        self.value = value
    }
    public func compareTo(tagValue:Float)-> Bool {
        return false
    }
    
    override func matches(obj: Element) throws -> Bool {
         // Get the value of the tag and convert to float
        guard
            let tagVal = obj.tags[key]?.withOptionalUnitToDoubleOrNull()
        else {return false}
            let tagFloat = Float(tagVal)
        return compareTo(tagValue: tagFloat)
    }
}

public class HasDateTagLessThan: CompareDateTagValue {
    override func compareTo(tagValue: Date) -> Bool {
        tagValue.compare(dateFilter.date).rawValue < 0
    }
    public override var description: String{
        "check_date < \(self.dateFilter)"
    }
}

public class HasDateTagGreaterThan: CompareDateTagValue {
    override func compareTo(tagValue: Date) -> Bool {
        tagValue.compare(dateFilter.date).rawValue > 0
    }
    public override var description: String{
        "check_date > \(self.dateFilter)"
    }
}

public class HasDateTagLessOrEqualThan: CompareDateTagValue {
    override func compareTo(tagValue: Date) -> Bool {
        tagValue.compare(dateFilter.date).rawValue <= 0
    }
    public override var description: String {
        "check_date <= \(self.dateFilter)"
    }
}

public class HasDateTagGreaterOrEqualThan: CompareDateTagValue {
    override func compareTo(tagValue: Date) -> Bool {
        tagValue.compare(dateFilter.date).rawValue >= 0
    }
    public override var description: String{
        "check_date >= \(self.dateFilter)"
    }
}


public class CompareDateTagValue : ElementFilter {
    let key : String
    let dateFilter: DateFilter
    init(key: String, dateFilter: DateFilter) {
        self.key = key
        self.dateFilter = dateFilter
    }
    
    func compareTo(tagValue: Date) -> Bool {
        return false
    }
    
    override func matches(obj: Element) throws -> Bool {
        guard let tagValue = obj.tags[key]?.toCheckDate() else {return false}
        return compareTo(tagValue: tagValue)
    }
}

public class TagOlderThan : CompareTagAge {
    
    public override var description: String {
        "\(key) older \(dateFilter)"
    }
    override func compareTo(tagValue: Date) -> Bool {
        tagValue.compare(dateFilter.date).rawValue < 0
    }
}

public class TagNewerThan : CompareTagAge {
    
    override func compareTo(tagValue: Date) -> Bool {
        tagValue.compare(dateFilter.date).rawValue > 0 // Compare
    }
}

public class CompareTagAge : ElementFilter {
    
    let key: String
    let dateFilter: DateFilter
    init(key: String, dateFilter: DateFilter) {
        self.key = key
        self.dateFilter = dateFilter
    }
    
    func compareTo(tagValue: Date) -> Bool {
        // Default return false
        return false
    }
    
    override func matches(obj: Element) throws -> Bool {
        if(compareTo(tagValue: Date(timeIntervalSince1970: TimeInterval(obj.timestampEdited)))) {return true}
        let lastCheckDateKeys = ResurveyUtils.getLastCheckDateKeys(key: key)
        let keyDates = lastCheckDateKeys.compactMap{obj.tags[$0]?.toCheckDate()}
      
        return   keyDates.contains {compareTo(tagValue: $0)}
    }
}

public class ElementOlderThan : CompareElementAge {
    
    public override var description: String {
        "older \(dateFilter)"
    }
    
    override func compareTo(tagValue: Date) -> Bool {
        tagValue.compare(dateFilter.date).rawValue < 0
    }
}

public class ElementNewerThan : CompareElementAge {
    
    public override var description: String {
        "newer \(dateFilter)"
    }
    
    override func compareTo(tagValue: Date) -> Bool {
        tagValue.compare(dateFilter.date).rawValue > 0
    }
}

public class CompareElementAge : ElementFilter {
    let dateFilter: DateFilter
    init(dateFilter: DateFilter) {
        self.dateFilter = dateFilter
    }
    
    func compareTo(tagValue: Date) -> Bool {
        // Default return false
        return false
    }
    override func matches(obj: Element) throws -> Bool {
        compareTo(tagValue: Date(timeIntervalSince1970: TimeInterval(obj.timestampEdited)))
    }
}

// TODO: Classes to be written







public class CombineFilters : ElementFilter {
    
    let filters:[ElementFilter]
    
    init(filters: [ElementFilter]) {
        self.filters = filters
    }
    
    public override var description: String{
        filters.reduce("", {$0.description + " and " + $1.description})
    }
    override func matches(obj: Element) throws -> Bool {
        filters.allSatisfy{ try! $0.matches(obj: obj)} // May be a mistake
    }
}
