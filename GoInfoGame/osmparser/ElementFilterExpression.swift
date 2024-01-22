//
//  ElementFilterExpression.swift
//  QParser
//
//  Created by Naresh Devalapally on 1/6/24.
//

import Foundation

public class ElementFilterExpression {
    let elementTypes: Set<ElementsTypeFilter>
    let elementExprRoot: BooleanExpression<ElementFilter, Element>?
    
    init(elementTypes: Set<ElementsTypeFilter>, elementExprRoot: BooleanExpression<ElementFilter, Element>?) {
        self.elementTypes = elementTypes
        self.elementExprRoot = elementExprRoot
    }
    
    func matches(element: Element) -> Bool {
        includesElementType(elementType: element.type)
        && ( !element.tags.isEmpty || mayEvaluateToTrueWithNoTags)
        && (elementExprRoot?.matches(element) ?? true)
    }
//    
    func includesElementType(elementType :ElementType) -> Bool {
        switch (elementType){
        case .node :
          return  elementTypes.contains(.NODES)
        case .way:
          return   elementTypes.contains(.WAYS)
        case .relation:
         return elementTypes.contains(.RELATIONS)
        }
    }
    
    var mayEvaluateToTrueWithNoTags: Bool  {
        let mayEval = try? elementExprRoot?.mayEvaluateToTrueWithNoTags()
       return mayEval ?? true
    }
}

extension BooleanExpression<ElementFilter, Element> {
    func mayEvaluateToTrueWithNoTags() throws -> Bool{
        switch (self){
        case is Leaf<ElementFilter, Element> :
            return (self as! Leaf).value.mayEvaluateToTrueWithNoTags()
        case is AnyOf<ElementFilter, Element>:
            return try (self as! AnyOf).children.contains{ try $0.mayEvaluateToTrueWithNoTags()}
        case is AllOf<ElementFilter, Element>:
            return try (self as! AllOf).children.allSatisfy{ try $0.mayEvaluateToTrueWithNoTags()}
        case is Not<ElementFilter, Element>:
            return try (self as! Not).children.first!.mayEvaluateToTrueWithNoTags()
        default: throw IllegalStateException(msg: "Unexpected expression")
            
        }
        
        
    }
}

extension ElementFilter {
    func mayEvaluateToTrueWithNoTags() -> Bool {
        switch(self){
        case is CompareElementAge, is CompareTagAge :
            return true
        case is NotHasKey,
            is NotHasKeyLike,
            is NotHasTag,
            is NotHasTagValueLike,
            is HasTagValueLike,
            is NotHasTagLike:
            return true
        case is HasKey,
            is HasKeyLike,
            is HasTag,
            is HasTagLike,
            is CompareTagValue,
            is CompareDateTagValue:
            return false
        case is CombineFilters:
           return (self as! CombineFilters).filters.allSatisfy{$0.mayEvaluateToTrueWithNoTags()}
        default:
            return false // Not sure
        }
    }
}


//
//extension BooleanExpression<ElementFilter, Element> {
//    func mayEvaluateToTrueWithNoTags() -> Bool {
//        swtch(self){
//        case is Leaf: return value.m
//        }
//    }
//}
