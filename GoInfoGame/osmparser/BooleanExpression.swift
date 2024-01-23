//
//  BooleanExpression.swift
//  QParser
//
//  Created by Naresh Devalapally on 1/2/24.
//

import Foundation

open class Matcher<T>  {
    // This is marked as interface in kotlin. We changed to base class
    func matches  (obj: T) throws -> Bool {
        fatalError("Not implemented")
    }
}

public class Chain<I: Matcher<T>, T> : BooleanExpression<I, T> {
//    var nodes =
    internal var nodes = [BooleanExpression<I,T>]()
    
    var children: [BooleanExpression<I,T>] {
        return nodes
    }
    
    func addChild(child: BooleanExpression<I,T>) {
        child.parent = self
        nodes.append(child)
    }
    func removeChild(child: BooleanExpression<I,T>) {
        // Need to check this later
        nodes = nodes.filter{$0 !== child}
//        nodes.firstIndex(of: {$0 == child})
    }
    
    func replaceChild(replace oldChild: BooleanExpression<I,T>, with newChild: BooleanExpression<I,T>) {
        newChild.parent = self
//        nodes.replace([oldChild], with: [newChild])
        if let index = nodes.firstIndex(of: oldChild) {
            nodes[index] = newChild
        }
    }
    
    func flatten() {
        removeEmptyNodes()
        mergeNodesWithSameOperator()
    }
    
   private func replaceChildAt(at index: Int, with expressions: [BooleanExpression<I, T>]){
        nodes.remove(at: index)
       for expression in expressions.reversed() {
            
            nodes.insert(expression, at: index)
            expression.parent = self
        }
    }
    
    func removeEmptyNodes() {
        var index = 0
        while index < nodes.count {
            guard let child = nodes[index] as? Chain else {
                index += 1
                continue
            }
            if child.nodes.count == 1 && !(child is Not<I,T>){
//                nodes[index] = child.nodes.first!
                replaceChildAt(at: index, with: [child.nodes.first!])
                index -= 1
            } else {
                child.removeEmptyNodes()
            }
            index += 1
        }
    }
    
    func mergeNodesWithSameOperator() {
        //TODO: Improve this with a iterator
        var index = 0
        while index < nodes.count {
            guard let child = nodes[index] as? Chain else {
                index += 1
                continue
            }
            if (child is Not<I,T>){
                index += 1
                continue
            }
            child.mergeNodesWithSameOperator()
            
            if type(of: child) == type(of: self){
                replaceChildAt(at: index, with: child.children)
                index -= 1
            } else {
                child.removeEmptyNodes()
            }
            index += 1
        }
    }
}

public class BooleanExpression<I:Matcher<T>,T> : Equatable, CustomStringConvertible {
    public static func == (lhs: BooleanExpression<I, T>, rhs: BooleanExpression<I, T>) -> Bool {
        return lhs.description == rhs.description
    }
    
    var parent: Chain<I, T>? = nil
    func matches(_ obj: T)  -> Bool {
        fatalError("Subclass to implement the 'matches' method.")
    }
//    public var description: String = ""
    public var description: String {
        return ""
    }
    
}

public class Not<I:Matcher<T>, T> : Chain<I,T> {
    override func addChild(child: BooleanExpression<I, T>) {
       
        if (nodes.isEmpty) {
            return super.addChild(child: child)
        }
        else {
            print("Adding a second child to '!' (NOT) operator is not allowed")
        }
    }
    
    override func matches(_ obj: T) -> Bool {
        if let first = nodes.first {
            return  !first.matches(obj)
        }
        return false
    }
   
    public override var description: String {
        return "!\(self.nodes.first)"
    }
}

public class AnyOf<I:Matcher<T>, T> : Chain<I, T> {
    override func matches(_ obj: T) -> Bool {
        return  nodes.contains(where: {$0.matches(obj)})
    }
    public override var description: String {
//        return self.nodes.
        var joinedString = ""
        self.nodes.forEach { node in
            joinedString += (joinedString.isEmpty ? "" : " or ") + "\(node)"
        }
        return joinedString
    }
    
}

public class AllOf<I:Matcher<T>, T> : Chain<I, T> {
    override func matches(_ obj: T) -> Bool {
        return nodes.allSatisfy {$0.matches(obj)}
    }
    
    public override var description: String {
        var joinedString = ""
        self.nodes.forEach { node in
            joinedString += (joinedString.isEmpty ? "":" and ") + (node is AnyOf ? "(\(node))" : "\(node)")
        }
        
        return  joinedString
    }
}

public class Leaf<I:Matcher<T>, T> : BooleanExpression<I,T>{
    let value: I
    init(value:I) {
        self.value = value
    }
    override func matches(_ obj: T )  -> Bool {
        return try! value.matches(obj: obj)
    }
    public override var description: String {
        return "\(self.value)"
    }
    
}
