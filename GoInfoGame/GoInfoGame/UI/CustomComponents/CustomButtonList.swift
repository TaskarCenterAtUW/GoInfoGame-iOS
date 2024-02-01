//
//  CustomButtonList.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 01/02/24.
//

import SwiftUI

struct CustomButtonList: View {
    let buttons: [ButtonInfo]
    @Binding var selectedButton: ButtonInfo?
    
    var body: some View {
        VStack {
            ForEach(buttons) { buttonInfo in
                Button(action: {
                    self.selectedButton = buttonInfo
                }) {
                    Text(buttonInfo.label)
                }
                .padding()
            }
        }
    }
}

struct ButtonInfo: Identifiable {
    let id: Int
    let label: String
}
