//
//  StpesRampViewModel.swift
//  GoInfoGame
//
//  Created by Prashamsa on 28/11/23.
//

import Foundation

enum StepsRamp: CaseIterable {
    case none
    case bicycle
    case stroller
    case wheelchair
    
    func title() -> String {
        switch self {
        case .none:
            return "No (usable) ramp"
        case .bicycle:
            return "Bicycle ramp"
        case .stroller:
            return "Stroller ramp"
        case .wheelchair:
            return "Wheelchair ramp"
        }
    }
    
    func iconName() -> String {
        switch self {
        case .none:
            return "ramp_none"
        case .bicycle:
            return "ramp_bicycle"
        case .stroller:
            return "ramp_stroller"
        case .wheelchair:
            return "ramp_wheelchair"
        }
    }
    
    func tagValue() -> String {
        return ""
    }
}

class StepsRampViewModel: MultipleOptionsQuest {
    func validateElement(element: RealmOPElement) -> Bool {
        return false
    }
    
    var options: [QuestOption] = []
    private let networkRequest: NetworkRequest
    
    var maxSelectableItems: Int {
        return 1
    }
    
    var icon: String {
        return "ic_quest_steps_ramp"
    }
    
    var tag: String {
        return "Key:ramp"
    }
    
    var title: String {
        return NSLocalizedString("Do these steps have a ramp? What kind?", comment: "Do these steps have a ramp? What kind?")
    }
    
    init(networkRequest: NetworkRequest = URLSession(configuration: .default)) {
        self.networkRequest = networkRequest
        for ramp in StepsRamp.allCases {
            let option = StepsRampOption(ramp: ramp);
            self.options.append(option)
        }
    }
}
