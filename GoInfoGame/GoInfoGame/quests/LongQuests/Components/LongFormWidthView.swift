//
//  SidewalkSurfaceImageData.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 23/07/24.
//

import Foundation
import SwiftUI

struct LongFormWidthView: View {
    @Binding var feet: Int
    @Binding var inches: Int
    @State private var isInputValid: Bool = false
    @Binding var isConfirmAlert: Bool
    var unit: LengthUnit = .feetInch

    var body: some View {
        if unit == .feetInch {
            VStack {
                HStack {
                    TextField("Feet",text: Binding(
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
                    .accessibilityLabel(Text("Enter in Feet"))
                    .accessibilityHint(Text("Tap to input measurements in feet in the text field."))
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
                    .accessibilityLabel(Text("Enter in Inches"))
                    .accessibilityHint(Text("Tap to input measurements in inches in the text field."))
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
