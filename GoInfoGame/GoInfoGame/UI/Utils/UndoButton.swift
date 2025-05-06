//
//  UndoButton.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 06/05/25.
//

import SwiftUI

struct UndoButton: View {
    @State private var showSidebar = false
    @State private var undoItems: [UndoItem] = []

    var body: some View {
        ZStack(alignment: .leading) {
            if showSidebar {
                UndoSidebarView(
                    undoItems: undoItems,
                    onUndo: { id, type in
                        MapUndoManager.shared.undo(for: Int64(id), type: type)
                      //  undoItems = fetchUndoItems()
                    },
                    onClose: {
                        withAnimation {
                            showSidebar = false
                        }
                    }
                )
                .transition(.move(edge: .leading))
                .padding(.top, 20)
            } else {
                Button(action: {
                  //  undoItems = fetchUndoItems()
                    withAnimation {
                        showSidebar = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 135/255, green: 62/255, blue: 242/255))
                            .frame(width: 40, height: 40)
                            .shadow(radius: 5)

                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                }
                .padding(.leading, 12)
                .padding(.top, 20)
            }
        }
    }

//    func fetchUndoItems() -> [UndoItem] {
//        let changesets = DatabaseConnector.shared.getChangesets()
//    }
}
