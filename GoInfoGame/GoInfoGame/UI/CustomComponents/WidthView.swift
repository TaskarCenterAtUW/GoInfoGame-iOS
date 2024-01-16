//
//  WidthView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 09/01/24.
//

import SwiftUI

struct WidthView: View {
    @Binding var feet: Double
    @Binding var inches: Double
    @State private var isInputValid: Bool = false
    @Binding var isConfirmAlert: Bool

    var body: some View {
        VStack {
            HStack {
                TextField("Feet", value: $feet, formatter: NumberFormatter(), onEditingChanged: { _ in
                    validateInput()
                })
                .frame(width: 20)
                .padding(.horizontal)
                .overlay(Rectangle().frame(height: 1).padding(.top, 25).foregroundColor(.orange), alignment: .bottom)
                .textFieldStyle(PlainTextFieldStyle())
                .keyboardType(UIKeyboardType.numberPad)
                Text("'").font(.title)
                
                TextField("Inches", value: $inches, formatter: NumberFormatter(), onEditingChanged: { _ in
                    validateInput()
                })
                .frame(width: 20)
                .padding(.horizontal)
                .overlay(Rectangle().frame(height: 1).padding(.top, 25).foregroundColor(.orange), alignment: .bottom)
                .textFieldStyle(PlainTextFieldStyle())
                .keyboardType(UIKeyboardType.numberPad)
                Text("\"").font(.title)
                if isInputValid {
                    Button() {
                        isConfirmAlert = true
                    }label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(Font.system(size: 40))
                            .foregroundColor(.orange)
                    }
                }
            }
            
        }
    }
    private func validateInput() {
        isInputValid = feet > 0 && inches >= 0
    }
}

//#Preview {
//    WidthView()
//}
