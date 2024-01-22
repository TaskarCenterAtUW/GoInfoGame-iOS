//
//  OSMConfig.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/21/24.
//

import Foundation
struct OSMConfig {
    let baseUrl: String
    //https://waylyticsposm.westus2.cloudapp.azure.com/api/0.6/
    // For testing data upload
    
    // Make all the URLs here.
    static var production : OSMConfig {
        OSMConfig(baseUrl: "https://api.openstreetmap.org/api/0.6/")
    }
    
    static var test: OSMConfig {
        OSMConfig(baseUrl: "https://waylyticsposm.westus2.cloudapp.azure.com/api/0.6/")
    }
}
