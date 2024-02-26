//
//  OSMConfig.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/21/24.
//

import Foundation
/// OSMConfig structure to handle the configuration
///
public struct OSMConfig {
    public let baseUrl: String
    
    /// Production Openstreetmap server
    /// Links directly to OpenstreetMap server
    public static var production : OSMConfig {
        OSMConfig(baseUrl: "https://api.openstreetmap.org/api/0.6/")
    }
    
    /// Internal test server
    public static var test: OSMConfig {
        OSMConfig(baseUrl: "https://waylyticsposm.westus2.cloudapp.azure.com/api/0.6/")
    }
    /// Links to Dev server of OSM
    public static var testOSM : OSMConfig {
        OSMConfig(baseUrl: "\(url)api/0.6/")
    }
    
    public static var url: String {
        "https://master.apis.dev.openstreetmap.org/"
    }
}
