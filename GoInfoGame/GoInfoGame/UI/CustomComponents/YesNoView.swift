//
//  YesNoView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 11/01/24.
//

import SwiftUI

struct YesNoView: View {
    @State private var showAlert = false
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            Button {
                showAlert = true
            } label: {
                Text(LocalizedStrings.otherAnswers.localized)
                    .foregroundColor(.orange).font(.body)
                    .frame(maxWidth: .infinity)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("More Questions"))
            }
            .frame(minHeight: 50)
            Spacer()
            Divider().background(Color.gray).frame(height: 30)
            Button(LocalizedStrings.questGenericHasFeatureYes.localized) {
            }
            .foregroundColor(.orange)
            .frame(minWidth: 20, maxWidth: 80, minHeight: 50)
            Divider().background(Color.gray).frame(height: 30)
            Button(LocalizedStrings.questGenericHasFeatureNo.localized) {
            }
            .foregroundColor(.orange)
            .frame(minWidth: 20, maxWidth: 80, minHeight: 50)
        }
    }
}

#Preview {
    YesNoView()
}
