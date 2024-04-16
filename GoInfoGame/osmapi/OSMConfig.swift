//
//  OSMConfig.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/21/24.
//

import Foundation
import SwiftUI

/// OSMConfig structure to handle the configuration
///
public struct OSMConfig {
    
    @AppStorage("baseUrl") private static var selectedBaseUrl: String = ""
    
    
    public let baseUrl: String
    
    public static var testPOSM: OSMConfig {
        OSMConfig(baseUrl: "\(selectedBaseUrl)/api/0.6/")
    }
    
    public static var productionOSM: OSMConfig {
        OSMConfig(baseUrl: "https://api.openstreetmap.org/api/0.6/")
    }
    
//    /// Production Openstreetmap server
//    /// Links directly to OpenstreetMap server
//    public static var production : OSMConfig {
//        OSMConfig(baseUrl: "https://api.openstreetmap.org/api/0.6/")
//    }
//    
//    /// Internal test server
//    public static var test: OSMConfig {
//        OSMConfig(baseUrl: "https://waylyticsposm.westus2.cloudapp.azure.com/api/0.6/")
//    }
//    /// Links to Dev server of OSM
//    public static var testOSM : OSMConfig {
//        OSMConfig(baseUrl: "\(url)api/0.6/")
//    }
//    
//    /// Links to Dev server of POSM
//    public static var testPOSM: OSMConfig {
//        OSMConfig(baseUrl: "\(posmUrl)api/0.6/")
//    }
//    
//    public static var url: String {
//        "https://master.apis.dev.openstreetmap.org/"
//    }
//    
//    public static var posmUrl: String {
//        "https://workspaces-osm-stage.sidewalks.washington.edu/"
//    }
    
   
}
