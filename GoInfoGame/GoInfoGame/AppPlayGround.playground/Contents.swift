import UIKit
import SwiftOverpassAPI
import RealmSwift

//var greeting = "Hello, playground"
let overpassManager = OverpassRequestManager()

//17.4554726,78.3709717,17.4607127,78.3764648
/**
 minLatitude : 37.784834000000004
- minLongitude : -122.40741700000001
- maxLatitude : 37.786834
- maxLongitude : -122.405417
 */

let dbConnector = DatabaseConnector.shared
//
//overpassManager.makeOverpassRequest(forBoundingBox:  37.784834000000004,-122.40741700000001,37.786834,-122.405417) {  elements in
//    print(elements)
//    print(elements.count)
////    let visualizations = self?.overpassManager.visualise(elements: elements)
////    if let visualizations = visualizations {
////        self?.addVisualizations(visualizations)
////
////    }
//    var ways:[OPWay] = []
//    for (node,element) in elements{
//        if element is OPWay {
//            ways.append(element as! OPWay)
//        }
//    }
//    dbConnector.saveElements(ways)
//
//    // Store all the elements
////    filterElements(elements: elements)
//}

let sampleQuery = "ways with ((highway = footway or foot = yes) and !width)"
let keywords = ["with","=","or","and","!","(",")"]
let stringWithCursor = StringWithCursor(stringValue:sampleQuery)
stringWithCursor.retreatBy(x: 2)
// This has to be split to
// 1. filterTagEqual (highway, footway)
// 2. filterTagEqual (foot, yes)
// 3. or Operator for the above two
// 4. filterTagNotExists for width
// 5. Find intersection of above

func filterTagEqualValue(elements: [RealmOPElement], tag:String, value:String) -> Array<RealmOPElement>{
   let filtered =  elements.filter { element in
       let contains = element.tags.contains { elementTag in
            elementTag.key == tag && elementTag.value == value
        }
        return contains
    }
    return Array(filtered)
}

func filterNotEqualValue(elements: [RealmOPElement], tag:String, value:String) -> Array<RealmOPElement>{
    let filtered =  elements.filter { element in
        let contains = element.tags.contains { elementTag in
             elementTag.key == tag && elementTag.value != value
         }
         return contains
     }
     return Array(filtered)
 }

func filterTagNotExist(elements: [RealmOPElement], tag:String) -> Array<RealmOPElement> {
    let filtered = elements.filter { element in
        let tagKeys = element.tags.map{$0.key}
        return !tagKeys.contains(tag)
    }
    return filtered
}

func unionOperator(firstArray: [RealmOPElement], secondArray:[RealmOPElement])-> Array<RealmOPElement>{
    let set1 = Set(firstArray)
    let set2 = Set(secondArray)
    let unionSet = set1.union(set2)
    let unionArray = Array(unionSet)
    return unionArray
}

func andOperator(firstArray:[RealmOPElement], secondArray:[RealmOPElement])-> Array<RealmOPElement> {
    let set1 = Set(firstArray)
    let set2 = Set(secondArray)
    let unionSet = set1.intersection(set2)
    let intersectionElements = Array(unionSet)
    return intersectionElements
}


let elements = Array(dbConnector.getElements())

let firstFilteredItems: [RealmOPElement] = filterTagEqualValue(elements:elements,tag:"highway",value:"footway")

let secondFilteredItems : [RealmOPElement] = filterTagEqualValue(elements: elements, tag: "footway", value: "sidewalk")
    
let firstIds = firstFilteredItems.map{$0.id}
let secondIds = secondFilteredItems.map{$0.id}
let commonIds = firstIds.filter{secondIds.contains($0)}

let unionItems = unionOperator(firstArray: firstFilteredItems, secondArray: secondFilteredItems)

let noWidthItems = filterTagNotExist(elements: Array(elements), tag: "width")

let sidewalkWidthQuests = andOperator(firstArray: unionItems, secondArray: noWidthItems)


let sidewalkWithQ = andOperator(firstArray: unionOperator(firstArray: filterTagEqualValue(elements: elements, tag: "highway", value: "footway"), secondArray: filterNotEqualValue(elements: elements, tag: "foot", value: "yes")), secondArray: filterTagNotExist(elements: elements, tag: "width"))









//
//func filterElements(elements:[Int:OPElement]) {
//    print("hello")
//    print(elements.count)
//
//    for (node,element) in elements {
//        print(element)
//        print(node)
//        if element is OPWay {
//
//        }
//    }
//}
