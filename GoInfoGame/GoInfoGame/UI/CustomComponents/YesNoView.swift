//
//  YesNoView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 11/01/24.
//

import SwiftUI

struct YesNoView: View {
    var body: some View {
        HStack(spacing: 20){
            Divider().background(Color.gray).frame(height: 30)
            Button(LocalizedStrings.questGenericHasFeatureYes.localized) {
            }.foregroundColor(.orange).frame(minWidth: 20,maxWidth: .infinity,minHeight: 50)
            Divider().background(Color.gray).frame(height: 30)
            Button(LocalizedStrings.questGenericHasFeatureNo.localized) {
            }.foregroundColor(.orange).frame(minWidth: 20,maxWidth: .infinity,minHeight: 50)
        }
    }
}

#Preview {
    YesNoView()
}
