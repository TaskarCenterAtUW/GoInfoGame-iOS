//
//  CustomSureAlert.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 18/02/24.
//

import SwiftUI

struct CustomSureAlert: View {
    let alertTitle: String /// Title of the alert
    let content: String /// Main content of the alert
    let leftBtnLabel: String /// Label for the left button (usually cancel)
    let rightBtnLabel: String /// Label for the right button (usually confirm)
    let isDontShowCheckVisible: Bool /// Flag indicating if the "Don't show again" checkbox should be visible
    let onCancel: () -> Void /// Closure to handle cancel action
    let onConfirm: () -> Void /// Closure to handle confirm action
    
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
        }, leftActionText: leftBtnLabel, rightActionText: rightBtnLabel, leftButtonAction: onCancel, rightButtonAction: onConfirm, height: 200, width: 270)
    }
}

#Preview {
    CustomSureAlert(alertTitle: "", content: LocalizedStrings.questSourceDialogNote.localized,leftBtnLabel: "", rightBtnLabel: "", isDontShowCheckVisible: true, onCancel: {}, onConfirm: {})
}
