//
//  SingleSelectionQuest.swift
//  GoInfoGame
//
//  Created by Prashamsa on 28/11/23.
//

import Foundation

protocol MultipleOptionsQuest: Quest {
    var options: [QuestOption] { get }
    var maxSelectableItems: Int { get }
}
