//
//  BoundingBox.swift
//  QParser
//
//  Created by Naresh Devalapally on 1/3/24.
//

import Foundation

class BoundingBox : Codable {
    let min: LatLon
    let max: LatLon
    // Need constructor and other stuff for precondition
    var crosses180thMeridian : Bool {
        // have to write actual implementaion
        false
    }
    
    func splitAt180thMeridian() -> [BoundingBox] {
        //TODO: Write this function
        return []
    }
    
    func toPolygon() -> [LatLon] {
        return [
            min,
            LatLon(latitude: min.latitude, longitude: max.longitude),
            max,
            LatLon(latitude: max.latitude, longitude: min.longitude),
            min
        ]
    }
}
