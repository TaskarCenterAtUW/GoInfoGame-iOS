//
//  CrossingIslandViewModel.swift
//  GoInfoGame
//
//  Created by Prashamsa on 30/11/23.
//

import Foundation

class CrossingIslandViewModel: ConfirmationQuest {
    var networkRequest: NetworkRequest
    var accpetTitle: String {
        return "Yes"
    }
    
    var rejectTitle: String {
        return "No"
    }
    
    var icon: String {
        return "ic_quest_pedestrian_crossing_island"
    }
    
    var tag: String {
        return "Key:crossing:island"
    }
    
    var title: String {
        return NSLocalizedString("Does this pedestrian crossing have an island?", comment: "Does this pedestrian crossing have an island?")
    }
    
    init(networkRequest: NetworkRequest) {
        self.networkRequest = networkRequest
    }    
}
