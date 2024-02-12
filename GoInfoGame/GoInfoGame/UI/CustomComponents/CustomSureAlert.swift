//
//  CustomSureAlert.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 13/02/24.
//

import SwiftUI

struct CustomSureAlert: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        CustomAlert(title: "Are you sure you checked this on-site?", content: {
            VStack {
                Text("Only information that was found on a survey should be entered.")
                Spacer()
                HStack {
                    Image(systemName: "square")
                        .foregroundColor(.gray)
                    Text("Don't show again for this session")
                }
            }
        }, leftActionText: "CANCEL", rightActionText: "YES, I AM SURE", leftButtonAction: onCancel, rightButtonAction: onConfirm, height: 200, width: 270)
    }
}

#Preview {
    CustomSureAlert(onCancel: {}, onConfirm: {})
}
