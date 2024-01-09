//
//  AddSideWalksWidthView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 09/01/24.
//

import SwiftUI

struct AddSideWalksWidthView: View {
    @State private var showAlert = false
    var body: some View {
        VStack{
            WidthView(feet: 0.0, inches: 0.0)
            Divider()
            Button {
                showAlert = true
            } label: {
                Text("OTHER ANSWERS...")
            }
            .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("More Questions"))
        }
    }
}

#Preview {
    AddSideWalksWidthView()
}
