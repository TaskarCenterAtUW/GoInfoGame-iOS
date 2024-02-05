//
//  SidewalkSurfaceForm.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 05/02/24.
//

import SwiftUI

struct SidewalkSurfaceForm: QuestForm ,View {
    func applyAnswer(answer: SidewalkSurfaceAnswer) {
    }
    typealias AnswerClass = SidewalkSurfaceAnswer
    @State private var selectedImage : String?
    @State private var showAlert = false
    let imagesFromSurfaces: [ImageData] = SELECTABLE_WAY_SURFACES.compactMap { surfaceString in
        let lowercaseSurfaceString = surfaceString.lowercased()
        
        if let surface = Surface(rawValue: lowercaseSurfaceString) {
            return ImageData(id: surfaceString, type: lowercaseSurfaceString, imageName: "surface_\(lowercaseSurfaceString)", tag: surface.rawValue, optionName: "\(lowercaseSurfaceString)")
        } else {
            print("Invalid Surface: \(surfaceString)")
            return nil
        }
    }

    var body: some View {
        VStack (alignment: .leading){
            QuestionHeader(icon: Image("sidewalk_surface"), title: LocalizedStrings.questSidewalkSurfaceTitle.localized, subtitle: "Street").padding(.bottom,10)
            VStack(alignment: .leading){
                Text(LocalizedStrings.select.localized).font(.caption).foregroundColor(.gray)
                ImageGridItemView(gridCount: 4, isLabelBelow: true, imageData: imagesFromSurfaces, isImageRotated: false, isDisplayImageOnly: false, onTap: { (type, tag) in
                    print("Clicked: \(type), Tag: \(tag)")}, selectedImage: $selectedImage)
                Divider()
                HStack() {
                    Spacer()
                    Button {
                        showAlert = true
                    } label: {
                        Text(LocalizedStrings.otherAnswers.localized).foregroundColor(.orange)
                    }.frame(alignment: .center)
                    Spacer()
                }.padding(.top,10)
            }        .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2))
        }
        .padding()
    }
}

#Preview {
    SidewalkSurfaceForm()
}
