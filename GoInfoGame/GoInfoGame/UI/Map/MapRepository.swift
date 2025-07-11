
//
//  Repository.swift
//  GoInfoGame
//
//  Created by Prashamsa on 30/06/25.
//

import Foundation

enum SatelliteOption: Identifiable, Hashable {
    case none
    case apple
    case wmts(SatelliteServer)

    var id: String {
        switch self {
        case .none: return "none"
        case .apple: return "apple"
        case .wmts(let layer): return layer.id
        }
    }

    var name: String {
        switch self {
        case .none: return "None"
        case .apple: return "Apple Satellite"
        case .wmts(let layer): return layer.name
        }
    }
    
    static func == (lhs: SatelliteOption, rhs: SatelliteOption) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

protocol MapRepositoryProtocol {
    func fetchAvailableServers() async throws -> SatelliteServers
}

class MapRepository: MapRepositoryProtocol {
    let netowrkClient: NetworkHandler
    init(netowrkClient: NetworkHandler = NetworkManager()) {
        self.netowrkClient = netowrkClient
    }
    
    func fetchAvailableServers() async throws -> SatelliteServers {
        return try await netowrkClient.fetchData(request: GetWMTSLayersReqeust())
    }
}

struct GetWMTSLayersReqeust: APIRequest {
    var urlRequest: URLRequest? {
        guard let url = Bundle.main.url(forResource: "WMTSLayers", withExtension: "json") else {
            return nil
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        return urlRequest
    }
}
