//
//  ConfirmationQuest.swift
//  GoInfoGame
//
//  Created by Prashamsa on 28/11/23.
//

import Foundation

protocol ConfirmationQuest: Quest {
    var accpetTitle: String { get }
    var rejectTitle: String { get }
}
