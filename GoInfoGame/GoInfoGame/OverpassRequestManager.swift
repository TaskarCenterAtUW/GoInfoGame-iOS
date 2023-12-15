//
//  OverpassRequestManager.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 15/11/23.
//

import Foundation
import SwiftOverpassAPI

class OverpassRequestManager {
    private let client: OPClient

    init() {
        client = OPClient()
        client.endpoint = .kumiSystems
    }

    func makeOverpassRequest(forBoundingBox minLatitude: Double,
                             _ minLongitude: Double, _ maxLatitude: Double,
                             _ maxLongitude: Double,
                             completionHandler: @escaping ([Int : OPElement]) -> ()) {
        let boundingBox = OPBoundingBox(minLatitude: minLatitude, minLongitude: minLongitude, maxLatitude: maxLatitude, maxLongitude: maxLongitude)
        var query = ""
        do {
            query = try OPQueryBuilder()
                .setTimeOut(180)
                .setElementTypes([.way, .node])
                .setBoundingBox(boundingBox)
               // .addTagFilter(key: "footway", value: "sidewalk")
                .setOutputType(.geometry)
                .buildQueryString()
        } catch {
            print(error.localizedDescription)
        }


        client.fetchElements(query: query) { [weak self] fetchedElements in
                   self?.handleOverpassResponse(fetchedElements, completionHandler: { result in
                       completionHandler(result)
                   })
        }
    }

    private func handleOverpassResponse(_ result: OPClientResult, completionHandler: @escaping ([Int: OPElement]) -> ()) {
           DispatchQueue.main.async {
               switch result {
               case .failure(let error):
                   print("Overpass API request failed: \(error.localizedDescription)")
                   completionHandler([:])
                   
               case .success(let elements):
                   completionHandler(elements)
               }
           }
       }
       
    
    func visualise(elements: [Int: OPElement]) -> [Int: OPMapKitVisualization] {
        let visualizations = OPVisualizationGenerator
            .mapKitVisualizations(forElements: elements)
        return visualizations
    }
}


