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
class SidewalkSurface :Quest {
    typealias AnswerClass = SidewalkSurfaceAnswer
    
    func onAnswer(answer: SidewalkSurfaceAnswer) {
    }
    var title: String = "Sidewalk Surface"
    var filter: String = ""
    var icon: UIImage = #imageLiteral(resourceName: "sidewalk_surface.pdf")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var form : AnyView = AnyView(SidewalkSurfaceForm())
    var relationData: Element? = nil
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize:.LARGE )
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
