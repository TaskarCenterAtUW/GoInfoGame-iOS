//
//  QuestSelectionConfirmationView.swift
//  GoInfoGame
//
//  Created by Prashamsa on 28/11/25.
//

import SwiftUI

struct QuestSelectionConfirmationView: View {
    @Environment(\.dismiss) var dismiss
    private var questType: String
    private var onStartAnswer: () -> Void = { }
    private var onHideQuest: () -> Void = { }
    private var onClose: () -> Void = { }
    
    init(questType: String, onStartAnswer: @escaping () -> Void, onHideQuest: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.questType = questType
        self.onStartAnswer = onStartAnswer
        self.onHideQuest = onHideQuest
        self.onClose = onClose
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 20, content: {
            HStack(alignment: .center, content: {
                Text(L10n.Localizable.selectedType)
                    .font(FontFamily.Lato.bold.swiftUIFont(fixedSize: 18))
                    .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                
                Text(" " + questType)
                    .font(FontFamily.Lato.regular.swiftUIFont(fixedSize: 18))
                    .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                
                Spacer()
                
                CrossMarkButton(onDismiss: {
                    dismiss()
                    onClose()
                })
            })
            
            DottedLine()
                .padding(.bottom)
                        
            startAnswerButton
            
            hideQuestButton
            
            notNowButton
        })
        .padding()
    }
    
    private var startAnswerButton: some View {
        Button {
            dismiss()
            onStartAnswer()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Asset.Colors.huskyPurple.swiftUIColor)
                Text(L10n.Localizable.startAnsweringTheQuestions)
                    .foregroundStyle(.white)
                    .font(FontFamily.Lato.bold.swiftUIFont(fixedSize: 16))
                    .multilineTextAlignment(.center)
            }
            .frame(height: 50)
        }
    }
    
    private var hideQuestButton: some View {
        Button {
            dismiss()
            onHideQuest()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Asset.Colors.huskyPurple.swiftUIColor, lineWidth: 2.0)
                    .background(.clear)
                Text(L10n.Localizable.hideThisQuest)
                    .font(FontFamily.Lato.bold.swiftUIFont(fixedSize: 16))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
            }
            .frame(height: 50)
        }
    }
    
    private var notNowButton: some View {
        Button {
            dismiss()
            onClose()
        } label: {
            Text(L10n.Localizable.notNow)
                .font(FontFamily.Lato.bold.swiftUIFont(fixedSize: 16))
                .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
        }
    }
}

#Preview {
    QuestSelectionConfirmationView(questType: "Sidewalk") {
        
    } onHideQuest: {
        
    } onClose: {
        
    }
}
