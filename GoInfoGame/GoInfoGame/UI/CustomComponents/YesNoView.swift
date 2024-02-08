//
//  YesNoView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 11/01/24.
//

import SwiftUI

enum YesNoButtonAction {
    case yes
    case no
    case other
}
func getYesNoBoolValue(_ action: YesNoButtonAction) -> Bool {
    switch action {
    case .yes:
        return true
    default:
        return false
    }
}
struct YesNoView: View {
    let onYesNoAnswerSelected: (YesNoButtonAction) -> Void
    let actionButton3Label: String
    init(actionButton3Label: String, onYesNoAnswerSelected: @escaping (YesNoButtonAction) -> Void) {
            self.actionButton3Label = actionButton3Label
            self.onYesNoAnswerSelected = onYesNoAnswerSelected
        }
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            Button {
                onYesNoAnswerSelected(.other)
            } label: {
                Text(actionButton3Label)
                    .foregroundColor(.orange).font(.body)
                    .frame(maxWidth: .infinity)
            }
            .frame(minHeight: 50)
            Spacer()
            Divider().background(Color.gray).frame(height: 30)
            Button(LocalizedStrings.questGenericHasFeatureYes.localized) {
                onYesNoAnswerSelected(.yes)
            }
            .foregroundColor(.orange)
            .frame(minWidth: 20, maxWidth: 80, minHeight: 50)
            Divider().background(Color.gray).frame(height: 30)
            Button(LocalizedStrings.questGenericHasFeatureNo.localized) {
                onYesNoAnswerSelected(.no)
            }
            .foregroundColor(.orange)
            .frame(minWidth: 20, maxWidth: 80, minHeight: 50)
        }
    }
}

#Preview {
    YesNoView(actionButton3Label: ""){ test in
        print(test)
    }
}
