//
//  KerbHeight.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 02/04/24.
//
import Foundation
import UIKit
import SwiftUI
import osmparser

class KerbHeight: QuestBase, Quest {
    var questId: String = "19"
    
    func onAnswer(answer: KerbHeightTypeAnswer) {
        var finalTags:[String:String] = [:]
        if let rData = self.relationData {
        /// expected tag for .kerbRamp & .lowered is same
        /// changing tag from "lowered_and_sloped" to "lowered"  for kerbRamp
            if answer == KerbHeightTypeAnswer.kerbRamp {
                finalTags = ["kerb": "lowered_and_sloped"]
            } else {
                finalTags = ["kerb": "\(answer.osmValue)"]
            }
            self.updateTags(id: rData.id, tags: finalTags, type: rData.type)
        }
    }
    var title: String = "Kerb Height"
    var filter: String = ""
    var icon: UIImage = #imageLiteral(resourceName: "kerb_type.pdf")
    var wikiLink: String = ""
    var changesetComment: String = "Determine the heights of kerbs"
    var relationData: Element? = nil
    var _internalExpression: ElementFilterExpression?
    var displayUnit: DisplayUnit {
        let uid = String(self.relationData?.id ?? 0)
        return DisplayUnit(title: self.title, description: "Kerb Height", id: "\(uid)-\(questId)",parent: self,sheetSize:.XLARGE )
    }
    var filterExpression: ElementFilterExpression? {
        if(_internalExpression != nil){
            return _internalExpression
        }
        else {
            _internalExpression = try? filter.toElementFilterExpression()
            return _internalExpression
        }
    }
    var form: AnyView {
        get{
            return AnyView(self.internalForm as! KerbHeightForm)
        }
    }
    override init() {
        super.init()
        self.internalForm = KerbHeightForm(action: { [self] answer in
            self.onAnswer(answer: answer)
        })
    }
 
    func copyWithElement(element: Element) -> any Quest {
        let q = KerbHeight()
        q.relationData = element
        return q
    }
    typealias AnswerClass = KerbHeightTypeAnswer
}

