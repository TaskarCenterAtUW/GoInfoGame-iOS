//
//  AddStepsInclineView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 12/01/24.
//

import SwiftUI

struct AddStepsInclineView: View {
    @State private var showAlert = false
    let imageData: [ImageData] = [
        ImageData(id:"UP",type: "none", imageName: "steps-incline-up", tag: "up", optionName: LocalizedStrings.questStepsInclineUp.localized),
        ImageData(id:"UP_REVERSED",type: "bicycle", imageName: "steps-incline-up-reversed", tag: "down", optionName: LocalizedStrings.questStepsInclineUp.localized),
    ]
    var body: some View {
        VStack (alignment: .leading){
            Text(LocalizedStrings.select.localized).font(.caption).foregroundColor(.gray)
            ImageGridItemView(gridCount: 2, isLabelBelow: true, imageData: imageData, isImageRotated: true, onTap: { (type, tag) in
                print("Clicked: \(type), Tag: \(tag)")})
            Divider()
            HStack() {
                Spacer()
                Button {
                    showAlert = true
                } label: {
                    Text(LocalizedStrings.otherAnswers.localized).foregroundColor(.orange)
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("More Questions"))
                }.frame(alignment: .center)
                Spacer()
            }.padding(.top,10)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: .gray, radius: 2, x: 0, y: 2))
    }
}

#Preview {
    AddStepsInclineView()
}
