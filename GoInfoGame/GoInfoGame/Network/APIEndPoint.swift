//
//  APIEndPoint.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 16/08/24.
//

import Foundation
import osmapi

struct APIEndpoint {
    let path: String
    let method: String
    let body: Data?
    let headers: [String: String]?
    
    
    static let login = { (loginParams:Data) in APIEndpoint(path: "/authenticate", method: "POST", body: loginParams, headers: ["Content-Type":"application/json"]) }
    
    static let fetchWorkspaceList = APIEndpoint(path: "/workspaces/mine", method: "GET", body: nil, headers: nil)
    
    static let fetchLongQuests = { (workspaceId: String) in APIEndpoint(path: "/workspaces/\(workspaceId)/quests/long", method: "GET", body: nil, headers: ["Content-Type":"application/json"]) }
    
    static let fetchOSMElements = { (left: Double, bottom: Double, right: Double, top: Double, workspaceID: String) in
          let header = [
            "X-Workspace": workspaceID
        ]
      return APIEndpoint(path: "/map.json?bbox=\(left),\(bottom),\(right),\(top)", method: "GET", body: nil, headers: header) }
    
    static let openChangesets = { (accessToken: String, workspaceId:String ,body: Data)  in
        
        let header = [
            "Authorization" : "Bearer \(accessToken)",
            "X-Workspace": "\(workspaceId)",
            "Content-Type" : "application/xml"
        ]
        
        return APIEndpoint(path: "/changeset/create", method: "PUT", body: body, headers: header) }
    
    static let updateWay = { (accessToken: String, wayID: String, body: Data) in
        
        let header = [
            "Authorization" : "Bearer \(accessToken)",
            "Content-Type" : "application/xml"
        ]
        
       return APIEndpoint(path: "/way/\(wayID)", method: "PUT", body: body, headers: header)}
    
    static let fetchLatestWay = { (workspaceId: String, wayId: String) in
        let header = [
            "X-Workspace": workspaceId,
            "Content-Type": "application/json"
        ]
        
        return APIEndpoint(path: "/way/\(wayId).json", method: "GET", body: nil, headers: header)
        
    }
    
    static let fetchLatestNode = { (workspaceId: String, nodeId: String) in
        let header = [
            "X-Workspace": workspaceId,
            "Content-Type": "application/json"
        ]
        
        return APIEndpoint(path: "/node/\(nodeId).json", method: "GET", body: nil, headers: header)
        
    }
    
    static let uploadChangeset = { (accessToken: String,changesetId:String ,workspaceId: String, body: Data) in
            let header = [
                "Authorization": "Bearer \(accessToken)",
                "X-Workspace": workspaceId,
                "Content-Type": "application/xml"
            ]
        return APIEndpoint(path: "/changeset/\(changesetId)/upload", method: "POST", body: body, headers: header)
    }
    
    static let fetchuserProfile = { (userName: String, accessToken: String) in
        
        let header = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type":"application/json"
        ]
        
       return APIEndpoint(path: "/user-profile?user_name=\(userName)", method: "GET", body: nil, headers: header) }
}

