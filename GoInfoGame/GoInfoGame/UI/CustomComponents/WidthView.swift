//
//  WidthView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 09/01/24.
//

import SwiftUI

enum LengthUnit {
    case feetInch
    case meters
}

struct WidthView: View {
    @Binding var feet: Int
    @Binding var inches: Int
    @State private var isInputValid: Bool = false
    @Binding var isConfirmAlert: Bool
    var unit: LengthUnit = .feetInch

    var body: some View {
        if unit == .feetInch {
            VStack {
                HStack {
                    TextField("Feet", text: Binding(
                        get: { "\(self.feet)" },
                        set: {
                            if let value = NumberFormatter().number(from: $0) {
                                self.feet = value.intValue
                            } else {
                                self.feet = 0
                            }
                            validateInput()
                        }
                    ))
                    .frame(width: 20)
                    .padding(.horizontal)
                    .overlay(Rectangle().frame(height: 1).padding(.top, 25).foregroundColor(.orange), alignment: .bottom)
                    .textFieldStyle(PlainTextFieldStyle())
                    .keyboardType(UIKeyboardType.numberPad)

                    Text("'").font(.title)

                    TextField("Inches", text: Binding(
                        get: { "\(self.inches)" },
                        set: {
                            if let value = NumberFormatter().number(from: $0) {
                                self.inches = value.intValue
                            } else {
                                self.inches = 0
                            }
                            validateInput()
                        }
                    ))
                    .frame(width: 20)
                    .padding(.horizontal)
                    .overlay(Rectangle().frame(height: 1).padding(.top, 25).foregroundColor(.orange), alignment: .bottom)
                    .textFieldStyle(PlainTextFieldStyle())
                    .keyboardType(UIKeyboardType.numberPad)
                    Text("\"").font(.title)
                    if isInputValid {
                        Button() {
                            isConfirmAlert = true
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .font(Font.system(size: 40))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        } else if unit == .meters {
            HStack {
                TextField("Inches", text: Binding(
                    get: { "\(self.inches)" },
                    set: {
                        if let value = NumberFormatter().number(from: $0) {
                            self.inches = value.intValue
                        } else {
                            self.inches = 0
                        }
                        validateInput()
                    }
                ))
                .frame(width: 20)
                .padding(.horizontal)
                .overlay(Rectangle().frame(height: 1).padding(.top, 25).foregroundColor(.orange), alignment: .bottom)
                .textFieldStyle(PlainTextFieldStyle())
                .keyboardType(UIKeyboardType.numberPad)

                Text("m").font(.title)
            }
        }
    }

    private func validateInput() {
        isInputValid = feet > 0 && inches >= 0
    }
}

#Preview {
    WidthView(feet: .constant(0), inches: .constant(0), isConfirmAlert: .constant(false))

}
