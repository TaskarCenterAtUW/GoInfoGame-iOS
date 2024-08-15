//
//  APIEndPoint.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 16/08/24.
//

import Foundation

struct APIEndpoint {
    let path: String
    let method: String
    let body: Data?
    let headers: [String: String]?
    
    
    static let login = { (loginParams:Data) in APIEndpoint(path: "/authenticate", method: "POST", body: loginParams, headers: nil) }
    
    static let fetchWorkspaceList = APIEndpoint(path: "/workspaces/mine", method: "GET", body: nil, headers: nil)
    
    static let fetchLongQuests = { (workspaceId: String) in APIEndpoint(path: "/workspaces/\(workspaceId)/quests/long", method: "GET", body: nil, headers: nil) }
    
    static let fetchOSMElements = APIEndpoint(path: <#T##String#>, method: <#T##String#>, body: <#T##Data?#>, headers: <#T##[String : String]?#>)
    
    
    

}
