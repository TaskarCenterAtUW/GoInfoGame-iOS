//
//  Untitled.swift
//  GoInfoGame
//
//  Created by Achyut Kumar Maddela on 12/02/25.
//

import osmapi

class UserNodesHelper {
    
    class func getPowerPole(lat: Double, lon: Double, changeset:Int, tags: [String: String]) -> OSMNode {
        return OSMNode(type: "node", id: -1, lat: lat, lon: lon, timestamp: Date(), version: 0, changeset: changeset, user: "", uid: 0, tags: tags)
    }
    
//    class func getFireHydrant(lat: Double, lon: Double, changeset:Int) -> OSMNode {
//        return OSMNode(type: "node", id: -1, lat: lat, lon: lon, timestamp: Date(), version: 0, changeset: changeset, user: "", uid: 0, tags: ["fire":"hydrant"])
//    }
//    
//    class func getBench(lat: Double, lon: Double, changeset:Int) -> OSMNode {
//        return OSMNode(type: "node", id: -1, lat: lat, lon: lon, timestamp: Date(), version: 0, changeset: changeset, user: "", uid: 0, tags: ["amenity":"bench"])
//    }
//    
//    class func getBollard(lat: Double, lon: Double, changeset:Int) -> OSMNode {
//        return OSMNode(type: "node", id: -1, lat: lat, lon: lon, timestamp: Date(), version: 0, changeset: changeset, user: "", uid: 0, tags: ["barrier":"bollard"])
//    }
//    
//    class func getManhole(lat: Double, lon: Double, changeset:Int) -> OSMNode {
//        return OSMNode(type: "node", id: -1, lat: lat, lon: lon, timestamp: Date(), version: 0, changeset: changeset, user: "", uid: 0, tags: ["man_made":"manhole"])
//    }
//    
//    class func getStreetLamp(lat: Double, lon: Double, changeset:Int) -> OSMNode {
//        return OSMNode(type: "node", id: -1, lat: lat, lon: lon, timestamp: Date(), version: 0, changeset: changeset, user: "", uid: 0, tags: ["highway":"street_lamp"])
//    }
//    
//    class func getWasteBasket(lat: Double, lon: Double, changeset:Int) -> OSMNode {
//        return OSMNode(type: "node", id: -1, lat: 9, lon: 9, timestamp: Date(), version: 0, changeset: 5, user: "", uid: 0, tags: ["amenity":"waste_basket"])
//    }
//    
    
    
    
    
    
    
    
    
    
    
    
}
