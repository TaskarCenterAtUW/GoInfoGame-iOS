//
//  QuestProtocols.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/17/24.
//

import Foundation
import UIKit
import SwiftUI
import osmparser
import MapKit

protocol Quest {
    associatedtype AnswerClass // The class that represents answer
    var title:String {get}
    var filter: String {get}
    var icon: UIImage {get}
    var wikiLink: String {get}
    var changesetComment: String {get}
    var form : AnyView {get}
    var relationData : Any? {get set}
    func onAnswer(answer:AnswerClass)
    
    var displayUnit: DisplayUnit { get}
    var filterExpression : ElementFilterExpression? { get  }
}

class QuestBase {
   public var internalForm: (any QuestForm)? = nil
    
}
// Adds default method and implementation
extension Quest {
    
    func isApplicable(element:Element) ->  Bool {
        
        guard let filterExpression = filterExpression else {
            return false
        }
        if((filterExpression.includesElementType(elementType: .node) && element is Node)
           || (filterExpression.includesElementType(elementType: .way) && element is Way)){
            return filterExpression.matches(element: element)
        }
        return false
    }
    
    var filterExpression : ElementFilterExpression? {
        
        return try? filter.toElementFilterExpression() // This is a costly operation
    }
}


struct DisplayUnit : Identifiable {
    let title:String
    let description : String
    let id = UUID()
    let parent: (any Quest)?
    let sheetSize : SheetSize?
}

protocol QuestForm {
    associatedtype AnswerClass
    
    func applyAnswer(answer:AnswerClass)
    
    var action: ((_ answer:AnswerClass)->Void)? {get set}
}

//struct DisplayUnitWithCoordinate: Identifiable {
//    let displayUnit: DisplayUnit
//    let coordinateInfo: CLLocationCoordinate2D
//    let id = UUID()
//}
