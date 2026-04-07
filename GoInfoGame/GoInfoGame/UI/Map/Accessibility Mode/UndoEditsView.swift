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
    @State var selectedItem: UndoItem?
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(alignment: .leading, content: {
                    pageHeadding
                        .padding(.bottom)
                    
                    DottedLine()
                    if viewModel.undoItems.isEmpty {
                        VStack(alignment: .center) {
                            Spacer()
                            NoEditsView()
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        List {
                            ForEach(viewModel.undoItems, id: \.date) { section in
                                Section {
                                    ForEach(section.items.sorted(by: { e1, e2 in
                                        e1.timestamp > e2.timestamp
                                    })) { item in
                                        Button {
                                            self.selectedItem = item
                                        } label: {
                                            ZStack {
                                                Color.white
                                                UndoItemView(undoItem: item)
                                                    .listRowInsets(EdgeInsets())
                                            }
                                            
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .listRowInsets(EdgeInsets())
                                    }
                                } header: {
                                    Text(section.date.formatted(date: .long, time: .omitted))
                                        .font(FontFamily.Lato.bold.swiftUIFont(size: 14, relativeTo: .subheadline))
                                        .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(nil)
                                        .accessibilityLabel(section.date.formatted(date: .long, time: .omitted))
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .listRowSpacing(20)
                        .padding(.bottom, 20)
                        
                    }
                    
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
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .accessibilityLabel(L10n.Localizable.undoEdits)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    CrossMarkButton {
                        dismiss()
                    }
                    .accessibilityLabel(L10n.Localizable.closeUndoEditsScreen)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .sheet(item: $selectedItem) { item in
            UndoItemConfirmationView(undoItem: item) {
                viewModel.undo(item: item)
            } onClose: {
                self.selectedItem = nil
            }
            .presentationDetents([.fraction(0.7)])
            .interactiveDismissDisabled()
            .presentationDragIndicator(.hidden)
            .applyPresentationSizingPage()
        }
        .onReceive(MapViewPublisher.shared.dismissSheet) { scenario in
            if case .undoDone(_) = scenario {
                viewModel.loadUndoItems()
            }
        }
    }
    
    private var pageHeadding: some View {
        VStack(alignment: .leading, spacing: 5.0, content: {
            Text(L10n.Localizable.undoYourRecentChanges)
                .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                .foregroundColor(Asset.Colors._42526ETextFieldText.swiftUIColor)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .accessibilityLabel(L10n.Localizable.undoYourRecentChanges)
            
            Text(L10n.Localizable.selectTheQuestBasedOnDateAndTimeForPreviewRevert)
                .font(FontFamily.Lato.medium.swiftUIFont(size: 14, relativeTo: .body))
                .foregroundColor(Asset.Colors._42526ETextFieldText.swiftUIColor)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .accessibilityLabel(L10n.Localizable.selectTheQuestBasedOnDateAndTimeForPreviewRevert)
        })
    }
    
    private var goBackToPreviousScreen: some View {
        Button {
            dismiss()
        } label: {
            HStack {
                Image(systemName: "arrow.left")
                Text(L10n.Localizable.goBackToPreviousScreen)
                    .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .accessibilityLabel(L10n.Localizable.goBackToPreviousScreen)
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
