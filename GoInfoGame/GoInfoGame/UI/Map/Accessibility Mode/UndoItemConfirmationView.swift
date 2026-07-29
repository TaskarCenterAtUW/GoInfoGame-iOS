//
//  UndoItemConfirmationView.swift
//  GoInfoGame
//
//  Created by Prashamsa on 02/12/25.
//

import SwiftUI

struct UndoItemConfirmationView: View {
    @Environment(\.dismiss) var dismiss
    
    private var onRevertChanges: () -> Void = { }
    private var onClose: () -> Void = { }
    
    private var undoItem: UndoItem
    
    init(undoItem: UndoItem, onRevertChanges: @escaping () -> Void, onClose: @escaping () -> Void ) {
        self.onRevertChanges = onRevertChanges
        self.onClose = onClose
        self.undoItem = undoItem
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 20, content: {
            HStack(alignment: .center, content: {
                Text(L10n.Localizable.undoTheFollowingChanges)
                    .font(FontFamily.Lato.bold.swiftUIFont(size: 18, relativeTo: .headline))
                    .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .accessibilityLabel(L10n.Localizable.undoTheFollowingChanges)
                
                Spacer()
                
                CrossMarkButton(onDismiss: {
                    dismiss()
                    onClose()
                })
            })
            
            DottedLine()

            VStack(alignment: .leading, content: {
                HStack {
                    VStack(alignment: .leading, spacing: 10, content: {
                        
                        HStack {
                            (
                                Text(L10n.Localizable.type)
                                    .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                                +
                                Text(": " + (undoItem.questType ?? "Not Avilable"))
                                    .font(FontFamily.Lato.regular.swiftUIFont(size: 16, relativeTo: .headline))
                            )
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(L10n.Localizable.type): \(undoItem.questType ?? "Not Available")")
                        }
                        
                        HStack {
                            (
                                Text(L10n.Localizable.dateTime)
                                    .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                                +
                                Text(": " + (undoItem.timestamp.formatted(date: .long, time: .shortened)))
                                    .font(FontFamily.Lato.regular.swiftUIFont(size: 16, relativeTo: .headline))
                            )
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(L10n.Localizable.dateTime): \(undoItem.timestamp.formatted(date: .long, time: .shortened))")
                        }
                    })
                    .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                    
                    Spacer()
                    
                    Image(undoItem.iconName)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .cornerRadius(20)
                    
                }
            })
            
            DottedLine()
            
            List {
                ForEach(undoItem.tags, id: \.key) { item in
                    EditedTagView(tagUpdate: item)
                        .listRowInsets(EdgeInsets())
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .listRowSpacing(10)
            .padding(.bottom, 20)
            .listRowSeparator(.hidden)
            
            DottedLine()
            
            HStack {
                revertChangesButton
                
                cancelButton
            }
            
        })
        .padding()
    }
    
    private var revertChangesButton: some View {
        Button {
            dismiss()
            onRevertChanges()
        } label: {
            ZStack {
                // A created feature has no prior tags to revert to — undoing it
                // deletes the element outright (see StoredChangeset.isCreatedElement).
                Text(undoItem.isCreatedElement ? "Delete Feature" : L10n.Localizable.revertChanges)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Asset.Colors.ff0041Red.swiftUIColor)
                    .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                    .cornerRadius(25)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .accessibilityLabel(Text(undoItem.isCreatedElement ? "Delete Feature" : L10n.Localizable.revertChanges))
            }
        }
    }
    
    private var cancelButton: some View {
        Button {
            dismiss()
            onClose()
        } label: {
            ZStack {
                Text(L10n.Localizable.cancel)
                    .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(25)
                    .overlay(content: {
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Asset.Colors.huskyPurple.swiftUIColor, lineWidth: 2.0)
                            .background(.clear)
                    })
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                    .accessibilityLabel(Text(L10n.Localizable.cancel))
                
            }
        }
    }
}

#Preview {
    UndoItemConfirmationView(undoItem: UndoItem(elementId: 101, type: .node, changedKeys: ["key1", "Key2"], id: "402322", timestamp: Date(), questType: "Sidewalk", tags: [(.added, "Key1", "Value 1"), (.modified, "Key2", "Value 2")], iconName: "sidewalk"), onRevertChanges: {
    }, onClose: {
    })
}
