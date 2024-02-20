//
//  CustomNoteAlert.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 19/02/24.
//
import SwiftUI
// Custom alert to display leave a note confirmation, contains :
/// Description text
/// Text for left action button (cancel)
/// Text for right action button (confirm)
/// Action closure for left button
/// Action closure for right button
struct CustomNoteAlert: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void
    var body: some View {
        CustomAlert(title: LocalizedStrings.questLeaveNewNoteTitle.localized, content: {
            VStack {
                Text(LocalizedStrings.questLeaveNewNoteDescription.localized)
                Spacer()
            }
        }, leftActionText: LocalizedStrings.questLeaveNewNoteNo.localized, rightActionText: LocalizedStrings.questLeaveNewNoteYes.localized, leftButtonAction: onCancel, rightButtonAction: onConfirm, height: 200, width: 270)
    }
}

#Preview {
    CustomNoteAlert(onCancel: {}, onConfirm: {})
}
