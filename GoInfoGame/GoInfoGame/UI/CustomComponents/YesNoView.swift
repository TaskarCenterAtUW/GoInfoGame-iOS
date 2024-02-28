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
        HStack(spacing: 0) {
            Spacer()
            Button(action: {
                action?(.other)
            }) {
                Text(actionBtnLabel)
                    .foregroundColor(.orange)
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
            }
            .frame(minHeight: 50)
            Spacer().frame(width: 0)
            Divider().background(Color.gray).frame(height: 30)
            Button(action: {
                action?(.yes)
            }) {
                Text(LocalizedStrings.questGenericHasFeatureYes.localized)
                    .foregroundColor(.orange)
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(maxWidth: 80)
            }
            .frame(minHeight: 50)
            Spacer().frame(width: 4)
            Divider().background(Color.gray).frame(height: 30)
            Button(action: {
                action?(.no)
            }) {
                Text(LocalizedStrings.questGenericHasFeatureNo.localized)
                    .foregroundColor(.orange)
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
            }
            .frame(minHeight: 50)
        }
    }
}

#Preview {
    YesNoView(actionBtnLabel: "")
}
