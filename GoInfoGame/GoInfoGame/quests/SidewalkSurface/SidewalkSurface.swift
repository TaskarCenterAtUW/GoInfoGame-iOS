//
//  SidewalkSurface.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 05/02/24.
//

import Foundation
import UIKit
import SwiftUI
import osmparser

class SidewalkSurface: QuestBase, Quest {
    var subTitle: String? = ""
    typealias AnswerClass = SidewalkSurfaceAnswer
    var title: String = "Sidewalk Surface"
    var filter: String = ""
    var icon: UIImage = #imageLiteral(resourceName: "sidewalk_surface.pdf")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var relationData: Element? = nil
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize:.LARGE )
    }
    var form: AnyView {
        get{
            return AnyView(self.internalForm as! SidewalkSurfaceForm)
        }
    }
    
    override init() {
        super.init()
        self.internalForm = SidewalkSurfaceForm(action: { [self] answer in
            self.onAnswer(answer: answer)
        })
    }
    
    func onAnswer(answer: SidewalkSurfaceAnswer) {
        if let rData = self.relationData , let surface = answer.value.surface?.rawValue {
            self.updateTags(id: rData.id, tags: ["sidewalk:Surface":surface], type: rData.type)
        }
    }
    
    func copyWithElement(element: Element) -> any Quest {
        let surface = SidewalkSurface()
        surface.relationData = element
        return surface
    }
}

struct SidewalkSurfaceAnswer {
    var value: SurfaceAndNote
}

struct SurfaceAndNote {
    var surface: Surface?
    var note: String?
}
