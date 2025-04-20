//
//  HiddenQuestManager.swift
//  GoInfoGame
//
//  Created by Achyut Kumar Maddela on 28/03/25.
//

import SwiftUI

struct HiddenQuest: Identifiable, Codable {
    let id: Int64
    let name: String
}

class HiddenQuestManager: ObservableObject {
    static let shared = HiddenQuestManager()

    @Published var hiddenQuests: [HiddenQuest] = []
    
    private init() {
        loadHiddenQuests()
    }

    func loadHiddenQuests(){
        let decoder = JSONDecoder()
        guard let data = UserDefaults.standard.data(forKey: "hiddenElements"), let decodedData = try? decoder.decode([HiddenQuest].self, from: data)  else { return }
        hiddenQuests = decodedData
    }
    
    func hideQuest(elementId: String, elementName: String, items: inout [DisplayUnitWithCoordinate]) {
        print(elementId)
        
        guard let questIdString = elementId.components(separatedBy: "-").first,
              let questId = Int(questIdString),
              let index = items.firstIndex(where: { $0.id == questId }) else {
            print("Invalid elementId or quest not found.")
            return
        }
        items[index].isHidden = true
        
        if let data = UserDefaults.standard.data(forKey: "hiddenElements") {
            let decoder = JSONDecoder()
            if let decodedData = try? decoder.decode([HiddenQuest].self, from: data) {
                hiddenQuests = decodedData
            }
        }
        if !hiddenQuests.contains(where: { $0.id == Int64(questId) }) {
            hiddenQuests.append(HiddenQuest(id: Int64(questId), name: elementName))
            saveHiddenQuests()
        }
    }
    
    func removeQuest(atOffsets indexSet: IndexSet) {
           hiddenQuests.remove(atOffsets: indexSet)
           saveHiddenQuests()
       }
    
    //remove all hidden quests
    func removeAllHiddenQuests() {
        hiddenQuests.removeAll()
        saveHiddenQuests()
    }
    
    func saveHiddenQuests() {
            let encoder = JSONEncoder()
            if let encodedData = try? encoder.encode(hiddenQuests) {
                UserDefaults.standard.set(encodedData, forKey: "hiddenElements")
            }
        }
}
