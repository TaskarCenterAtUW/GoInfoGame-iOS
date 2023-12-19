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
    func validateElement2(element: RealmOPElement) -> Bool {
        
        guard element.nodes.count > 0 else {
            return false
        }
        let highwayTag =  element.tags.filter { tag in
            return (tag.key == "highway" && tag.value == "steps")
        }
        
        if highwayTag.count == 0 {
            return false
        }
        
        let indoorTag =  element.tags.filter { tag in
            return (tag.key == "indoor")
        }
        
        if indoorTag.count == 1,
           indoorTag.first?.value != "no" {
            return false
        }
        
        let accessTag =  element.tags.filter { tag in
            return !(tag.key == "access" && (tag.value == "private" || tag.value == "no"))
        }
        
        if accessTag.count == 0 {
            return false
        }
        
        let conveyingTag =  element.tags.filter { tag in
            return (tag.key == "conveying")
        }
        
        if conveyingTag.count == 1,
           conveyingTag.first?.value != "no" {
            return false
        }
        //
        let rampTag =  element.tags.filter { tag in
            return (tag.key == "ramp" &&  tag.value != "separate")
        }
        
        if rampTag.count == 0 {
            return false
        }
        
        if !isRampValid(for: element) {
            return false
        }
        
        
        return true
    }
    
    func validateElement(element: RealmOPElement) -> Bool {
        
        /* val elementFilter = """
         ways with highway = steps
         and (!indoor or indoor = no)
         and access !~ private|no
         and (!conveying or conveying = no)
         and ramp != separate
         and (
         !ramp
         or (ramp = yes and !ramp:stroller and !ramp:bicycle and !ramp:wheelchair)
         or ramp = no and ramp older today -4 years
         or ramp older today -8 years
         )
         """*/
        
        guard element.nodes.count > 0 else { return false }
        
        if !(element.tags.contains(where: { $0.key == "highway" && $0.value == "steps" })) &&
            (!element.tags.contains(where: { $0.key == "indoor" }) || element.tags.first(where: { $0.key == "indoor" })?.value == "no") {
          return false
        }
        
        if element.tags.contains(where: { $0.key == "access" && ($0.value == "private" || $0.value == "no") }) &&
            (!element.tags.contains(where: { $0.key == "conveying" }) || element.tags.first(where: { $0.key == "conveying" })?.value == "no") {
            return false
        }
        
        if element.tags.contains(where: { $0.key == "ramp" && $0.value == "separate" }) {
            return false
        }
        
        if !isRampValid(for: element) {
            return false
        }
        
        return true
    }
    //For reference
    func validateElement3(element: RealmOPElement) -> Bool {
      guard element.nodes.count > 0 else { return false }

      // Highway and indoor conditions
      if !(element.tags.contains(where: { $0.key == "highway" && $0.value == "steps" })) ||
          (element.tags.contains(where: { $0.key == "indoor" })) && element.tags.first(where: { $0.key == "indoor" })?.value != "no" {
        return false
      }

      // Access and conveying conditions
      if element.tags.contains(where: { $0.key == "access" && ($0.value == "private" || $0.value == "no") }) ||
          (element.tags.contains(where: { $0.key == "conveying" })) && element.tags.first(where: { $0.key == "conveying" })?.value != "no" {
        return false
      }

      // Ramp exclusion
      if element.tags.contains(where: { $0.key == "ramp" && $0.value == "separate" }) {
        return false
      }

      // Ramp validation with early exit
      if !isRampValid(for: element) {
        return false
      }

      return true
    }
    func isRampValid(for element: RealmOPElement) -> Bool {
        
        /*(
         !ramp
         or (ramp = yes and !ramp:stroller and !ramp:bicycle and !ramp:wheelchair)
         or ramp = no and ramp older today -4 years
         or ramp older today -8 years
         )*/
        guard let rampTag = element.tags.first(where: { $0.key == "ramp" }) else {
            return true // Condition: !ramp
        }
        
        let rampValue = rampTag.value
        
        if rampValue == "yes" {
            // Condition: ramp = yes and !ramp:stroller and !ramp:bicycle and !ramp:wheelchair
            return element.tags.allSatisfy { tag in
                return tag.key != "ramp:stroller" && tag.key != "ramp:bicycle" && tag.key != "ramp:wheelchair"
            }
        } else if rampValue == "no" {
            // Condition: ramp = no and ramp older today -4 years
            // //check older than 8 years
            let dateToday = Date()
            let olderThanDate = Calendar.current.date(byAdding: .year, value: -4, to: dateToday)
            // if let rampDate = checkdate {
            //    return true
            // } else {
            //    return false
            // }
            return true
        } else {
            return false
        }
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
