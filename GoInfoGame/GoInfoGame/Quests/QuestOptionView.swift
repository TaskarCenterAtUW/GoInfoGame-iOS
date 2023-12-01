//
//  QuestOptionView.swift
//  GoInfoGame
//
//  Created by Prashamsa on 28/11/23.
//

import SwiftUI

struct QuestOptionView: View {
    var questOption: any QuestOption
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
                .cornerRadius(10.0)
                .overlay(
                    ZStack {
                        if let image = UIImage(named: questOption.icon) {
                            Image(uiImage: image)
                        }
                        VStack {
                            StrokeText(text: questOption.title, width: 0.5, color: .black)
                                .foregroundColor(.white)
                            
                        }
                    }
                )
        }
        .cornerRadius(12)
        .shadow(color: .gray, radius: 2, x: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, y: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/)
        .aspectRatio(contentMode: .fit)
    }
}

#Preview {
    QuestOptionView(questOption: StepsRampOption(ramp: .none))
}
                
struct StrokeText: View {
    let text: String
    let width: CGFloat
    let color: Color

    var body: some View {
        ZStack{
            ZStack{
                Text(text).offset(x:  width, y:  width)
                Text(text).offset(x: -width, y: -width)
                Text(text).offset(x: -width, y:  width)
                Text(text).offset(x:  width, y: -width)
            }
            .foregroundColor(color)
            Text(text)
        }
    }
}
