//
//  YesNoView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 11/01/24.
//

import SwiftUI
enum YesNoAnswer {
    case yes
    case no
    case other
    case unknown
}


struct YesNoView: View {

    var action: ((_ answer:YesNoAnswer) -> Void)?
    
    init(action: ((_ answer: YesNoAnswer) -> Void)? = nil) {
        self.action = action
    }
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            Button {
                action?(.other)
            } label: {
                Text(LocalizedStrings.otherAnswers.localized)
                    .foregroundColor(.orange).font(.body)
                    .frame(maxWidth: .infinity)
            }
            .frame(minHeight: 50)
            Spacer()
            Divider().background(Color.gray).frame(height: 30)
            Button(LocalizedStrings.questGenericHasFeatureYes.localized) {
                action?(.yes)
            }
            .foregroundColor(.orange)
            .frame(minWidth: 20, maxWidth: 80, minHeight: 50)
            Divider().background(Color.gray).frame(height: 30)
            Button {
                
                action?(.no)
            } label: {
                Text(LocalizedStrings.questGenericHasFeatureNo.localized)
                    .foregroundColor(.orange).font(.body)
                    .frame(maxWidth: .infinity)
            }
             
        }
    }
}

#Preview {
    YesNoView()
}
