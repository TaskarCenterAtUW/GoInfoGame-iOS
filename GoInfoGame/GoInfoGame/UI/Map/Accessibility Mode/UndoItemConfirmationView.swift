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
                    .font(FontFamily.Lato.bold.swiftUIFont(fixedSize: 18))
                    .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                
                
                
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
                            Text(L10n.Localizable.type)
                                .font(FontFamily.Lato.bold.swiftUIFont(fixedSize: 16))
                            
                            Text(": " + (undoItem.questType ?? "Not Avilable"))
                                .font(FontFamily.Lato.regular.swiftUIFont(fixedSize: 16))
                        }
                        
                        HStack {
                            Text(L10n.Localizable.dateTime)
                                .font(FontFamily.Lato.bold.swiftUIFont(fixedSize: 16))
                            
                            Text(": " + (undoItem.timestamp.formatted(date: .long, time: .shortened)))
                                .font(FontFamily.Lato.regular.swiftUIFont(fixedSize: 16))
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
            
            revertChangesButton
            
            cancelButton
        })
        .padding()
    }
    
    private var revertChangesButton: some View {
        Button {
            dismiss()
            onRevertChanges()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Asset.Colors.ff0041Red.swiftUIColor)
                Text(L10n.Localizable.revertChanges)
                    .foregroundStyle(.white)
                    .font(FontFamily.Lato.bold.swiftUIFont(fixedSize: 16))
                    .multilineTextAlignment(.center)
            }
            .frame(height: 50)
        }
    }
    
    private var cancelButton: some View {
        Button {
            dismiss()
            onClose()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Asset.Colors.huskyPurple.swiftUIColor, lineWidth: 2.0)
                    .background(.clear)
                Text(L10n.Localizable.cancel)
                    .font(FontFamily.Lato.bold.swiftUIFont(fixedSize: 16))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
            }
            .frame(height: 50)
        }
    }
}

#Preview {
    UndoItemConfirmationView(undoItem: UndoItem(elementId: 101, type: .node, changedKeys: ["key1", "Key2"], id: "402322", timestamp: Date(), questType: "Sidewalk", tags: [(.added, "Key1", "Value 1"), (.modified, "Key2", "Value 2")], iconName: "sidewalk"), onRevertChanges: {
    }, onClose: {
    })
}
