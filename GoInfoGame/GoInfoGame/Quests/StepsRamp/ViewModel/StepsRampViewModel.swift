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
        
        //        let filteredElements = allElements.filter { element in
        //            let highwayTags1 = element.tags.filter { tag in
        //                return tag.key == "highway" && highwayValues1.contains(tag.value)
        //            }
        //
        //            let highwayTags2 = element.tags.filter { tag in
        //                return tag.key == "highway" && highwayValues2.contains(tag.value)
        //            }
        //
        //            let areaTags = element.tags.filter { tag in
        //                return tag.key == "area" && tag.value != "yes"
        //            }
                    
        
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
            return (tag.key == "indoor" && tag.value == "no")
       }
        
        if indoorTag.count == 0 {
            return false
        }
        
//        let accessTag =  element.tags.filter { tag in
//            return (tag.key == "access" && (tag.value == "private" || tag.value == "no"))
//       }
//        
//        if accessTag.count == 0 {
//            return false
//        }
        
//        let conveyingTag =  element.tags.filter { tag in
//            return (tag.key == "conveying" &&  tag.value == "no")
//       }
//        
//        if conveyingTag.count == 0 {
//            return false
//        }
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
    
    func isRampValid(for element: RealmOPElement) -> Bool {
        
        /*(
          !ramp
          or (ramp = yes and !ramp:stroller and !ramp:bicycle and !ramp:wheelchair)
          or ramp = no and ramp older today -4 years
          or ramp older today -8 years
        )*/
        let rampTag = element.tags.filter { tag in
            return tag.key == "ramp"
        }

        if rampTag.isEmpty {
            // Condition: !ramp
            return true
        } else {
            let rampValue = rampTag.first?.value

            if rampValue == "yes" {
                // Condition: ramp = yes and !ramp:stroller and !ramp:bicycle and !ramp:wheelchair
                let strollerTag = element.tags.filter { $0.key == "ramp:stroller" }
                let bicycleTag = element.tags.filter { $0.key == "ramp:bicycle" }
                let wheelchairTag = element.tags.filter { $0.key == "ramp:wheelchair" }

                return strollerTag.isEmpty && bicycleTag.isEmpty && wheelchairTag.isEmpty
            } else if rampValue == "no" {
                // Condition: ramp = no and ramp older today -4 years
                // //check older than 8 years
                let dateToday = Date()
                let olderThanDate = Calendar.current.date(byAdding: .year, value: -4, to: dateToday)
//                if let rampDate = checkdate {
//                    return true
//                } else {
//                    return false
//                }
                return true
            } else {
               
                return false
            }
            
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
