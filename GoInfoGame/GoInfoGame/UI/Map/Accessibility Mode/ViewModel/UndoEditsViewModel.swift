//
//  UndoEditsViewModel.swift
//  GoInfoGame
//
//  Created by Prashamsa on 01/12/25.
//

import Foundation

class UndoEditsViewModel: ObservableObject {
    @Published var undoItems: [(date: Date, items: [UndoItem])] = []
    
    init(undoItems: [(date: Date, items: [UndoItem])]) {
        self.undoItems = undoItems
        loadUndoItems()
    }
    
    func loadUndoItems() {
        let undoItems = MapUndoManager.shared.getUndoItems()
        let groupdedUndoItems: Dictionary<Date, [UndoItem]> = Dictionary(grouping: undoItems, by: { item in
            return Calendar.current.startOfDay(for: item.timestamp)
        })
        
        let sortedGroups = groupdedUndoItems.map { ( $0.key, $0.value) }
        
        self.undoItems = sortedGroups
    }
    
    func undo(item: UndoItem) {
        MapUndoManager.shared.undo(for: item.id)
    }
}
