//
//  AddTactilePavingStepsView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 12/01/24.
//

import SwiftUI

struct AddTactilePavingStepsView: View {
    var body: some View {
        VStack(alignment:.leading){
            Text(LocalizedStrings.usuallyLooksLikeThis.localized).font(.caption).foregroundColor(.gray)
            Image("tactile_paving_illustration")
                .resizable()
                .scaledToFill()
            Divider()
            YesNoView()
        } .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2))
    }
}

#Preview {
    AddTactilePavingStepsView()
}
