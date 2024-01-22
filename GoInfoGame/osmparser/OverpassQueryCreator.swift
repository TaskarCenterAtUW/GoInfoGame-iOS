//
//  OverpassQueryCreator.swift
//  QParser
//
//  Created by Naresh Devalapally on 1/15/24.
//

import Foundation

public class OverpassQueryCreator {
    
    var elementTypes: [String]
    var setIdCounter: Int = 1
//    var dataSets: [BooleanExpression<ElementFilter, Element>: Int] = [:]
    
    init(_ elementTypes: Set<ElementsTypeFilter> , _ expr: BooleanExpression<ElementFilter, Element>?){
        self.elementTypes = elementTypes.toOqlNames()
    }
}

extension Set<ElementsTypeFilter> {
    func toOqlNames() -> [String] {
        if isSuperset(of: [ElementsTypeFilter.NODES, ElementsTypeFilter.WAYS, ElementsTypeFilter.RELATIONS]){
            return ["nwr"]
        }
        else if isSuperset(of: [ElementsTypeFilter.NODES, ElementsTypeFilter.WAYS]){
            return ["nw"]
        } else if isSuperset(of: [ElementsTypeFilter.WAYS, ElementsTypeFilter.RELATIONS]){
            return ["wr"]
        } else {
            return map { $0.osmQValue()}
        }
    }
}
