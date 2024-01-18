//
//  HandRailForm.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/18/24.
//

import SwiftUI

struct HandRailForm: View, QuestForm {
    
    func applyAnswer(answer: Bool) {
        
    }
    
    typealias AnswerClass = Bool
    
    
    
    var body: some View {
            QuestionHeader(icon: Image("steps_handrail"), title: "Do these steps have handrail?", subtitle: "")
        YesNoView()
        
    }
}

#Preview {
    HandRailForm()
}
