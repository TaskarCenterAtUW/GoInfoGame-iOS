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
    }

    func makeOverpassRequest(forBoundingBox minLatitude: Double, _ minLongitude: Double, _ maxLatitude: Double, _ maxLongitude: Double, completionHandler: @escaping ([String: Int]) -> ()) {
        let boundingBox = OPBoundingBox(minLatitude: minLatitude, minLongitude: minLongitude, maxLatitude: maxLatitude, maxLongitude: maxLongitude)
        var query = ""
        do {
            query = try OPQueryBuilder()
                .setTimeOut(180)
                .setElementTypes([.way, .relation, .node])
                .setBoundingBox(boundingBox)
                .setOutputType(.geometry)
                .buildQueryString()
        } catch {
            print(error.localizedDescription)
        }

        client.endpoint = .kumiSystems

        client.fetchElements(query: query) { [weak self] result in
            self?.handleOverpassResponse(result, completionHandler: { result in
                completionHandler(result)
            })
        }
    }

    private func handleOverpassResponse(_ result: OPClientResult, completionHandler: @escaping ([String: Int]) -> ()) {
        var nodeCount = 0
        var wayCount = 0
        var relCount = 0

        DispatchQueue.main.async {
            switch result {
            case .failure(let error):
                print(error.localizedDescription)

            case .success(let elements):
                for element in elements.values {
                    switch element {
                    case is OPNode:
                        nodeCount += 1
                    case is OPWay:
                        wayCount += 1
                    case is OPRelation:
                        relCount += 1
                    default:
                        print("NONE")
                    }
                }
                
                let resultDict = ["nodeCount": nodeCount, "wayCount": wayCount, "relCount": relCount]
                 completionHandler(resultDict)
            }
        }
    }
}
