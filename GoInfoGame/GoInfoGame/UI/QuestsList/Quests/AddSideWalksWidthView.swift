//
//  AddSideWalksWidthView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 09/01/24.
//

import SwiftUI

struct AddSideWalksWidthView: View {
    @State private var showAlert = false
    @State private var feet: Double = 0.0
    @State private var inches: Double = 0.0
    @State private var isConfirmAlert: Bool = false
    var selectedQuest: Ques?
    var body: some View {
        VStack{
            Text(selectedQuest?.answerTitle ?? "").font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.gray)
                .padding(.top,10)
            WidthView(feet: $feet, inches: $inches, isConfirmAlert: $isConfirmAlert)
            Divider()
            Button {
                showAlert = true
            } label: {
                Text("OTHER ANSWERS...").foregroundColor(.orange)
            }
            .padding(.top,10)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("More Questions"))
        }
        .alert(isPresented: $isConfirmAlert) {
            Alert(
                title: Text("Are you sure?"),
                message: Text("This width looks implausible. Remember, this should be the width from curb to curb, including on-street parking, bicycle lanes etc."),
                primaryButton: .default(Text("YES, IAM SURE")) {
                    print("OK button tapped")
                },
                secondaryButton: .default(Text("I WILL CHECK"))
            )
        }
    }
}

//#Preview {
//    AddSideWalksWidthView()
//}
