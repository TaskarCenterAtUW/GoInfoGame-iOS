//
//  WidthView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 09/01/24.
//

import SwiftUI

struct WidthView: View {
    @State private var feet: Double
    @State private var inches: Double

    init(feet: Double, inches: Double) {
        self._feet = State(initialValue: feet)
        self._inches = State(initialValue: inches)
    }

    var body: some View {
        HStack() {
            TextField("Feet", value: $feet, formatter: NumberFormatter())
                .frame(width: 20)
                .padding(.horizontal)
                .overlay(Rectangle().frame(height: 1).padding(.top, 25).foregroundColor(.blue), alignment: .bottom)
                .textFieldStyle(PlainTextFieldStyle())
            Text("'")

            TextField("Inches", value: $inches, formatter: NumberFormatter())
                .frame(width: 20)
                .padding(.horizontal)
                .overlay(Rectangle().frame(height: 1).padding(.top, 25).foregroundColor(.blue), alignment: .bottom)
                .textFieldStyle(PlainTextFieldStyle())
            Text("\"")
        }
        .padding()
    }
}

//#Preview {
//    WidthView()
//}
