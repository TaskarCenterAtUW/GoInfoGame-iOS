//
//  CustomSureAlert.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 18/02/24.
//

import SwiftUI

struct CustomSureAlert: View {
    let alertTitle: String
    let content: String
    let isDontShowCheckVisible: Bool
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        CustomAlert(title: alertTitle, content: {
            VStack {
                Text(content)
                Spacer()
                if isDontShowCheckVisible {
                    HStack {
                        Image(systemName: "square")
                            .foregroundColor(.gray)
                        Text(LocalizedStrings.dontShowAgain.localized)
                    }
                }
            }
        }, leftActionText: LocalizedStrings.undoConfirmNegative.localized, rightActionText: LocalizedStrings.questGenericConfirmationYes.localized, leftButtonAction: onCancel, rightButtonAction: onConfirm, height: 200, width: 270)
    }
}

#Preview {
    CustomSureAlert(alertTitle: "", content: LocalizedStrings.questSourceDialogNote.localized,isDontShowCheckVisible: true, onCancel: {}, onConfirm: {})
}
