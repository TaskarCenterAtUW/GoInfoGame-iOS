//
//  UndoButton.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 06/05/25.
//

import SwiftUI
import osmparser

struct UndoButton: View {
    var onPreview: (Int, ElementType) -> Void
    var onRemovePreview: () -> Void
    var onRevert: (String) -> Void

    @State private var showSidebar = false
    @State private var undoItems: [UndoItem] = []
    @State private var selectedUndoItem: UndoItem? = nil
    @State private var showUndoPopup = false

    var body: some View {
        ZStack(alignment: .leading) {
            if showSidebar {
                UndoSidebarView(
                    onUndo: { id in
                        onRevert(id)
                        undoItems = MapUndoManager.shared.getUndoItems()
                        withAnimation { showSidebar = false }
                    },
                    onClose: { withAnimation { showSidebar = false } },
                    onItemSelected: { item in
                        selectedUndoItem = item
                        showUndoPopup = true
                        onPreview(item.elementId, item.type)
                    }
                )
                .transition(.move(edge: .leading))
                .padding(.top, 20)
            } else {
                Button(action: {
                    undoItems = MapUndoManager.shared.getUndoItems()
                    withAnimation { showSidebar = true }
                }) {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 54, height: 54)
                            .shadow(radius: 5)

                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 28))
                            .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                    }
                    .shadow(radius: 10)
                }
                .padding(.leading, 12)
                .padding(.top, 20)
            }

            if showUndoPopup, let item = selectedUndoItem {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showUndoPopup = false
                        onRemovePreview()
                    }

                VStack(spacing: 16) {
                    Text("\(item.type == .way ? "Way" : "Node") #\(String(item.elementId))")
                        .font(.headline)

                    if !item.changedKeys.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Changed keys:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            ForEach(item.changedKeys, id: \.self) { key in
                                Text("• \(key)")
                                    .font(.caption)
                            }
                        }
                    }

                    HStack {
                        Button("Cancel") {
                            showUndoPopup = false
                            onRemovePreview()
                        }

                        Spacer()

                        Button("Revert") {
                            onRevert(item.id)
                            showUndoPopup = false
                            showSidebar = false
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .cornerRadius(8)
//                        .frame(width: 200)
                    }
                }
                .padding()
                .frame(maxWidth: 300)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 10)
            }
        }
    }
}

#Preview {
    UndoButton(onPreview: { id, type in
        
    }, onRemovePreview: {
         
    }, onRevert: { changesetid in
        
    })
}


