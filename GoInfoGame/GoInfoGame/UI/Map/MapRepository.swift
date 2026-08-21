
//
//  Repository.swift
//  GoInfoGame
//
//  Created by Prashamsa on 30/06/25.
//

import Foundation

enum SatelliteOption: Identifiable, Hashable {
    case none
    case wmts(SatelliteServer)

    var id: String {
        switch self {
        case .none: return "none"
        case .wmts(let layer): return layer.id
        }
    }

    var name: String {
        switch self {
        case .none: return "Default Imagery"
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
