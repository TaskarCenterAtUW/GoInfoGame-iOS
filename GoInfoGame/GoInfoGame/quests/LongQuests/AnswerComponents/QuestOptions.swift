//
//  ShortAnswersWithoutImage.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 31/07/24.
//

import SwiftUI

struct QuestOptions: View {
    
    let options: [QuestAnswerChoice]
    
    @State var selectedOption: String?
    
    var body: some View {
           ScrollView {
                   ForEach(options, id: \.self) { title in
                       Button(action: {
                           print("\(title) pressed")
                           self.selectedOption = title
                       }) {
                           Text(title)
                               .font(.custom("Lato-Bold", size: 14))
                               .foregroundColor(selectedOption == title ? Color.white : Color(red: 66/255, green: 82/255, blue: 110/255))
                               .padding()
                               .background(selectedOption == title ? Color(red: 135/255, green: 62/255, blue: 242/255) : Color(red: 245/255, green: 245/255, blue: 245/255))
                               .cornerRadius(25)
                       }
                     
                       .frame(maxWidth: .infinity, alignment: .leading)
                   }
           }
       }
}

#Preview {
    QuestOptions(options: ["Ashpalt", "Concrete", "Brick", "Others"], selectedOption: "")
}
