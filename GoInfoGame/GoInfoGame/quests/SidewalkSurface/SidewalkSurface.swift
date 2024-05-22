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
    var questId: String = "31"
    
    typealias AnswerClass = SidewalkSurfaceAnswer
    var title: String = "Sidewalk Surface"
    var filter: String = "ways with (highway=footway and footway = sidewalk) and !surface"
    var icon: UIImage = #imageLiteral(resourceName: "sidewalk_surface.pdf")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var relationData: Element? = nil
    var displayUnit: DisplayUnit {
        let uid = String(self.relationData?.id ?? 0)
        return DisplayUnit(title: self.title, description: "", id: "\(uid)-\(questId)",parent: self,sheetSize: .XLARGE)
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
            self.updateTags(id: rData.id, tags: ["surface":surface], type: rData.type)
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
