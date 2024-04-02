//
//  YesNoView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 11/01/24.
//

import SwiftUI

enum YesNoAnswer: String {
    case yes
    case no
    case other
    case unknown
}

struct YesNoView: View {

    var actionBtnLabel: String
        var action: ((_ answer: YesNoAnswer) -> Void)?
        
        init(actionBtnLabel: String, action: ((_ answer: YesNoAnswer) -> Void)? = nil) {
            self.actionBtnLabel = actionBtnLabel
            self.action = action
        }
    
    var body: some View {
        HStack {
            Spacer()
            Button {
                action?(.yes)
            } label: {
                Text(LocalizedStrings.questGenericHasFeatureYes.localized)
                    .foregroundColor(.orange)
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .frame(minHeight: 50)
            Spacer()
            Divider()
            Spacer()
            Button {
                action?(.no)
            } label: {
                Text(LocalizedStrings.questGenericHasFeatureNo.localized)
                    .foregroundColor(.orange)
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            Spacer()
        }
    }
}

#Preview {
    YesNoView(actionBtnLabel: "")
}
