//
//  BooleanExpressionBuilder.swift
//  QParser
//
//  Created by Naresh Devalapally on 1/2/24.
//

import Foundation

public class BooleanExpressionBuilder<I: Matcher<T>, T> {
    private var node: Chain<I,T> = BracketHelper()
    private var bracketCount = 0
    
    func addOpenBracket() {
        let group = BracketHelper<I,T>()
        node.addChild(child: group)
        node = group
        bracketCount += 1
//        print("bracket Count", bracketCount)
    }
    
    func addCloseBracket() throws {
        // check if bracketCount decremented is less than 0
        bracketCount -= 1
//        print("bracket Count", bracketCount)
        if(bracketCount < 0) {
            throw IllegalStateException(msg: "Closed one bracket too much")
        }
        while (!(node is BracketHelper)) {
            node = node.parent!
        }
        if node.parent != nil {
            node = node.parent!
        }
        if (node is Not){
            node = node.parent!
        }
    }
    
    func addValue(i: I){
        
        node.addChild(child: Leaf(value: i))
    }
    
    func addAnd() {
        if (!(node is AllOf)){
            let last = node.children.last
            let allOf = AllOf<I,T>()
            allOf.addChild(child: last!)
            node.replaceChild(replace: last!, with: allOf)
            node = allOf
        }
    }
    
    func addOr(){
        let allOf = node as? AllOf
        let group = node as? BracketHelper
        if (allOf != nil){
            let nodeParent = node.parent
            if (nodeParent is AnyOf){
                node = nodeParent!
            } else {
                nodeParent?.removeChild(child: allOf!)
                let anyOf = AnyOf<I,T>()
                anyOf.addChild(child: allOf!)
                nodeParent?.addChild(child: anyOf)
                node = anyOf
            }
        } else if (group != nil) {
            let last = node.children.last
            let anyOf = AnyOf<I, T>()
            node.replaceChild(replace: last!, with: anyOf)
            anyOf.addChild(child: last!)
            node = anyOf
        }
    }
    
//    func addValue(i: ) {
//        
//    }
    
    func addNot(){
        let not = Not<I,T>()
        node.addChild(child: not)
        node = not
    }
    
    func build() throws -> BooleanExpression<I,T>? {
        if(bracketCount > 0){
            throw IllegalStateException(msg: "Closed one bracket too little")
        }
        while (node.parent != nil){
            node = node.parent!
        }
        node.flatten()
        switch node.children.count {
        case 0 : return nil
        case 1 :
            let firstChild = node.children.first
            node.removeChild(child: firstChild!)
            return firstChild
        default: break
        }
        try node.ensureNoBracketNodes()
        return node
    }
}

private class BracketHelper<I: Matcher<T>, T>: Chain<I,T> {
    override func matches(_ obj: T) -> Bool {
//        throw IllegalStateException(msg: "Bracket cannot match")
        return false
    }
    override var description: String {
        return "BracketHelper"
    }
}

private extension Chain where I:Matcher<T> {
    func ensureNoBracketNodes() throws {
        if (self is BracketHelper) {
            throw IllegalStateException(msg: "BooleanExpression still contains a bracket node!")
        }
        var index = 0
        while index < children.count {
            guard let child = children[index] as? Chain else {
                index += 1
                continue
            }
            try child.ensureNoBracketNodes()
            index += 1
        }
    }
    
}
