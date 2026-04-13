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
    private var isAutoSelected: Bool = false
    
    init(questType: String, isAutoSelected: Bool, onStartAnswer: @escaping () -> Void, onHideQuest: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.questType = questType
        self.onStartAnswer = onStartAnswer
        self.onHideQuest = onHideQuest
        self.onClose = onClose
        self.isAutoSelected = isAutoSelected
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 20, content: {
            HStack(alignment: .center, content: {
                if isAutoSelected {
                    Text(L10n.Localizable.youVeArrived)
                        .font(FontFamily.Lato.bold.swiftUIFont(size: 18, relativeTo: .headline))
                        .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .accessibilityLabel(L10n.Localizable.youVeArrived)
                } else {
                    (
                        Text(L10n.Localizable.selectedType)
                            .font(FontFamily.Lato.bold.swiftUIFont(size: 18, relativeTo: .headline))
                        +
                        Text(" " + questType)
                            .font(FontFamily.Lato.regular.swiftUIFont(size: 18, relativeTo: .headline))
                    )
                    .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .accessibilityLabel("\(L10n.Localizable.selectedType) \(questType)")
                }
                
                Spacer()
                
                CrossMarkButton(onDismiss: {
                    dismiss()
                    onClose()
                })
            })
            .padding(.top, 20)
            
            DottedLine()
                .padding(.bottom)
            
            if isAutoSelected {
                VStack(alignment: .center, spacing: 30) {
                    Asset.reached.swiftUIImage
                    
                    Text(L10n.Localizable.youVeArrivedAtTheQuestLocation)
                        .font(FontFamily.Lato.bold.swiftUIFont(size: 24, relativeTo: .headline))
                        .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .accessibilityLabel(L10n.Localizable.youVeArrivedAtTheQuestLocation)
                    
                    HStack {
                        (
                            Text(L10n.Localizable.questType)
                                .font(FontFamily.Lato.bold.swiftUIFont(size: 18, relativeTo: .headline))
                            +
                            Text(": \(questType)")
                                .font(FontFamily.Lato.regular.swiftUIFont(size: 18, relativeTo: .headline))
                        )
                        .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .accessibilityLabel("\(L10n.Localizable.questType): \(questType)")
                    }
                }
                .padding(.bottom)
            }
                        
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
            Text(L10n.Localizable.startAnsweringTheQuestions)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Asset.Colors.huskyPurple.swiftUIColor)
                .foregroundStyle(.white)
                .cornerRadius(25)
                .font(FontFamily.Lato.bold.swiftUIFont(size: 16))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .accessibilityLabel(Text(L10n.Localizable.startAnsweringTheQuestions))
        }
    }
    
    private var hideQuestButton: some View {
        Button {
            dismiss()
            onHideQuest()
        } label: {
            Text(L10n.Localizable.hideThisQuest)
                .padding()
                .frame(maxWidth: .infinity)
                .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                .overlay {
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Asset.Colors.huskyPurple.swiftUIColor, lineWidth: 2.0)
                }
                .accessibilityLabel(Text(L10n.Localizable.hideThisQuest))
        }
    }
    
    private var notNowButton: some View {
        Button {
            dismiss()
            onClose()
        } label: {
            Text(L10n.Localizable.notNow)
                .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .accessibilityLabel(Text(L10n.Localizable.notNow))
        }
    }
}

#Preview {
    QuestSelectionConfirmationView(questType: "Sidewalk", isAutoSelected: true) {
        
    } onHideQuest: {
        
    } onClose: {
        
    }
}
