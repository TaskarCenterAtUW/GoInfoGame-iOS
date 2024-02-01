//
//  CustomButtonList.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 01/02/24.
//

import SwiftUI

struct CustomButtonList: View {
    let buttons: [ButtonInfo]
    let selectionChanged: (ButtonInfo?) -> Void
    
    var body: some View {
        VStack(alignment: .leading,spacing: 10) {
            ForEach(buttons) { buttonInfo in
                Button(action: {
                    selectionChanged(buttonInfo)
                }) {
                    Text(buttonInfo.label)
                }
            }
        }.padding(.top, 20)
    }
}

struct ButtonInfo: Identifiable {
    let id: Int
    let label: String
}
