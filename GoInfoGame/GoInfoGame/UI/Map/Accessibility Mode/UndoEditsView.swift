//
//  UndoEditsView.swift
//  GoInfoGame
//
//  Created by Prashamsa on 28/11/25.
//

import SwiftUI

struct UndoEditsView: View {
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject private var viewModel: UndoEditsViewModel = UndoEditsViewModel(undoItems: [])
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(alignment: .leading, content: {
                    pageHeadding
                        .padding(.bottom)
                    
                    DottedLine()
                    
                    List {
                        ForEach(viewModel.undoItems, id: \.date) { section in
                            Section {
                                ForEach(section.items.sorted(by: { e1, e2 in
                                    e1.timestamp > e2.timestamp
                                })) { item in
                                    UndoItemView(undoItem: item)
                                        .listRowInsets(EdgeInsets())
                                }
                            } header: {
                                Text(section.date.formatted(date: .long, time: .omitted))
                                    .font(FontFamily.Lato.bold.swiftUIFont(size: 14))
                                    .foregroundColor(Asset.Colors._83879BTextFiledTitle.swiftUIColor)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .listRowSpacing(20)
                    .padding(.bottom, 20)
                    
                    DottedLine()
                    HStack {
                        Spacer()
                        goBackToPreviousScreen
                        Spacer()
                    }
                    .padding()
                })
            }
            .padding()
            .onAppear() {
                viewModel.loadUndoItems()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text(L10n.Localizable.undoEdits)
                        .font(FontFamily.Lato.bold.swiftUIFont(size: 16))
                        .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    CrossMarkButton {
                        dismiss()
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private var pageHeadding: some View {
        VStack(alignment: .leading, spacing: 5.0, content: {
            Text(L10n.Localizable.undoYourRecentChanges)
                .font(FontFamily.Lato.bold.swiftUIFont(size: 16))
                .foregroundColor(Asset.Colors._42526ETextFieldText.swiftUIColor)
            Text(L10n.Localizable.selectTheQuestBasedOnDateAndTimeForPreviewRevert)
                .font(FontFamily.Lato.medium.swiftUIFont(size: 14))
                .foregroundColor(Asset.Colors._42526ETextFieldText.swiftUIColor)
        })
    }
    
    private var goBackToPreviousScreen: some View {
        Button {
            dismiss()
        } label: {
            HStack {
                Image(systemName: "arrow.left")
                Text(L10n.Localizable.goBackToPreviousScreen)
                    .font(FontFamily.Lato.bold.swiftUIFont(fixedSize: 16))
            }
            .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
            .padding(10)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Asset.Colors.huskyPurple.swiftUIColor, lineWidth: 2)
        )
    }
}

#Preview {
    UndoEditsView()
}
