//
//  OverpassRepository.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 25/11/23.
//

import Foundation
import SwiftOverpassAPI

// Why is this needed??

protocol OverpassDataProvider {
    func fetchData(
        forBoundingBox minLatitude: Double,
        _ minLongitude: Double,
        _ maxLatitude: Double,
        _ maxLongitude: Double,
        completion: @escaping ([Int : OPElement]) -> Void
    )
}

class OverpassRepository: OverpassDataProvider {
    
    func fetchData(
        forBoundingBox minLatitude: Double,
        _ minLongitude: Double,
        _ maxLatitude: Double,
        _ maxLongitude: Double,
        completion: @escaping ([Int : OPElement]) -> Void
    ) {
      
        completion([:])
    }
}
