//
//  OSMConfig.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/21/24.
//

import Foundation
public struct OSMConfig {
    public let baseUrl: String
    //https://waylyticsposm.westus2.cloudapp.azure.com/api/0.6/
    // For testing data upload
    
    // Make all the URLs here.
    public static var production : OSMConfig {
        OSMConfig(baseUrl: "https://api.openstreetmap.org/api/0.6/")
    }
    
    public static var test: OSMConfig {
        OSMConfig(baseUrl: "https://waylyticsposm.westus2.cloudapp.azure.com/api/0.6/")
    }
    
    public static var testOSM : OSMConfig {
        OSMConfig(baseUrl: "\(url)api/0.6/")
    }
    
    public static var url: String {
        "https://master.apis.dev.openstreetmap.org/"
    }
}
