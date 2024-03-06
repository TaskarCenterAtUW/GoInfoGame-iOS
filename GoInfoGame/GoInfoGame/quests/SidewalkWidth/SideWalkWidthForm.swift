//
//  AddSideWalksWidthView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 09/01/24.
//

import SwiftUI
import UIKit
import Combine


struct SideWalkWidthForm: View, QuestForm {
    typealias AnswerClass = WidthAnswer
    @State private var showAlert = false
    @State private var feet: Int = 0
    @State private var inches: Int = 0
    @State private var isConfirmAlert: Bool = false
    @State private var isKeyboardVisible: Bool = false // Track keyboard visibility
//    @Binding var subheading: String
    
//    init(subheading: Binding<String> = .constant("")){
//        _subheading = subheading
//    }
    
    
    
    var action: ((WidthAnswer) -> Void)?
    
    var body: some View {
        VStack{
            QuestionHeader(icon: Image("sidewalk-width-img"),
                           title: LocalizedStrings.questDetermineSidewalkWidth.localized,
                           subtitle: subheading)
            Text(LocalizedStrings.questRoadWithExplanation.localized).font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.gray)
                .padding(.top,10)
            WidthView(feet: $feet, inches: $inches, isConfirmAlert: $isConfirmAlert)
                .onReceive(Just(isConfirmAlert)) { isAlert in
                            if isAlert {
                                // Dismiss the keyboard when confirmation is given
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        }
            Divider()
            Button {
                showAlert = true
            } label: {
                Text(LocalizedStrings.otherAnswers.localized).foregroundColor(.orange)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("More Questions"))
            }
            .padding(.top,10)
            Spacer()
        }.padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .alert(isPresented: $isConfirmAlert) {
                Alert(
                    title: Text(LocalizedStrings.questGenericConfirmationTitle.localized),
                    message: Text(LocalizedStrings.questRoadWidthUnusualInputConfirmation.localized),
                    primaryButton: .default(Text(LocalizedStrings.questGenericConfirmationYes.localized)) {
                        processAnswer()
                    },
                    secondaryButton: .default(Text(LocalizedStrings.questGenericConfirmationNo.localized))
                )
            }
    }
    
    func processAnswer() {
        let width = self.convertFeetToMeter(feet: feet, inches: inches)
        let answer = WidthAnswer(width: width, units: "m", isARMeasurement: false)
        action?(answer)
    }
    
    func assignSubHeading(value:String) {
        self.subheading = value
    }
    
    func convertFeetToMeter(feet: Int, inches: Int)-> String {
        let meters = Double((feet * 12 + inches)) * 0.0254
        return String(format: "%.2f", meters)
    }
}

#Preview {
    SideWalkWidthForm()
}
