//
//  CustomSureAlert.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 18/02/24.
//

import SwiftUI

struct CustomSureAlert: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        CustomAlert(title: LocalizedStrings.questSourceDialogTitle.localized, content: {
            VStack {
                Text(LocalizedStrings.questSourceDialogNote.localized)
                Spacer()
                HStack {
                    Image(systemName: "square")
                        .foregroundColor(.gray)
                    Text(LocalizedStrings.dontShowAgain.localized)
                }
            }
        }, leftActionText: LocalizedStrings.undoConfirmNegative.localized, rightActionText: LocalizedStrings.questGenericConfirmationYes.localized, leftButtonAction: onCancel, rightButtonAction: onConfirm, height: 200, width: 270)
    }
}

#Preview {
    CustomSureAlert(onCancel: {}, onConfirm: {})
}
