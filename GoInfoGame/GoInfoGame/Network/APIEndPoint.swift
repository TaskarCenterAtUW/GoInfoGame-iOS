//
//  APIEndPoint.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 16/08/24.
//

import Foundation
import osmapi
import CoreLocation

struct APIEndpoint {
    let path: String
    let method: String
    let body: Data?
    let headers: [String: String]?
    let formData: [[String: Any]]?
    
    
    static let login = { (loginParams:Data) in APIEndpoint(path: "/authenticate", method: "POST", body: loginParams, headers: ["Content-Type":"application/json"], formData: nil) }
    
    static let refreshToken = { (refreshToken: String) in
        let headers = ["Content-Type":"application/json"]
        let postBody  = refreshToken.data(using: .utf8)
        return APIEndpoint(path: "/refresh-token",
                    method: "POST",
                    body: postBody,
                    headers: headers,
                    formData: nil)
        
    }
    
    static let fetchProjectGroupRoles = { (userId: String, accessToken: String) in
        let header = [
            "Authorization": "Bearer \(accessToken)"
        ]
        return APIEndpoint(path: "/project-group-roles/\(userId)?page_size=10000&page_no=1&sort_by=name", method: "GET", body: nil, headers: header, formData: nil)
    }

    static let fetchWorkspaceList = { (location: CLLocationCoordinate2D, radius: Int, gig_only: Bool, accessToken: String) in
           
            let header = [
                "Authorization" : "Bearer \(accessToken)"
            ]
        return APIEndpoint(path: "/workspaces/mine?lat=\(location.latitude.roundedTo7Digits())&lon=\(location.longitude.roundedTo7Digits())&radius=\(radius)&gig_only=\(gig_only)", method: "GET", body: nil, headers: header, formData: nil)}
    
    static let fetchWorkspaceDetails = { (workspaceId: String) in APIEndpoint(path: "/workspaces/\(workspaceId)", method: "GET", body: nil, headers: ["Content-Type":"application/json"], formData: nil) }
    
    static let fetchOSMElements = { (left: Double, bottom: Double, right: Double, top: Double, workspaceID: String) in
          let header = [
            "X-Workspace": workspaceID
        ]
        return APIEndpoint(path: "/map.json?bbox=\(left.roundedTo7Digits()),\(bottom.roundedTo7Digits()),\(right.roundedTo7Digits()),\(top.roundedTo7Digits())", method: "GET", body: nil, headers: header, formData: nil) }
    
    static let openChangesets = { (accessToken: String, workspaceId:String ,body: Data)  in
        
        let header = [
            "Authorization" : "Bearer \(accessToken)",
            "X-Workspace": "\(workspaceId)",
            "Content-Type" : "application/xml"
        ]
        
        return APIEndpoint(path: "/changeset/create", method: "PUT", body: body, headers: header, formData: nil) }
    
    static let updateWay = { (accessToken: String, wayID: String, body: Data) in
        
        let header = [
            "Authorization" : "Bearer \(accessToken)",
            "Content-Type" : "application/xml"
        ]
        
        return APIEndpoint(path: "/way/\(wayID)", method: "PUT", body: body, headers: header, formData: nil)}
    
    static let fetchLatestWay = { (workspaceId: String, wayId: String) in
        let header = [
            "X-Workspace": workspaceId,
            "Content-Type": "application/json"
        ]
        
        return APIEndpoint(path: "/way/\(wayId).json", method: "GET", body: nil, headers: header, formData: nil)
        
    }
    
    static let fetchLatestNode = { (workspaceId: String, nodeId: String) in
        let header = [
            "X-Workspace": workspaceId,
            "Content-Type": "application/json"
        ]
        
        return APIEndpoint(path: "/node/\(nodeId).json", method: "GET", body: nil, headers: header, formData: nil)
        
    }
    
    static let uploadChangeset = { (accessToken: String,changesetId:String ,workspaceId: String, body: Data) in
            let header = [
                "Authorization": "Bearer \(accessToken)",
                "X-Workspace": workspaceId,
                "Content-Type": "application/xml"
            ]
        return APIEndpoint(path: "/changeset/\(changesetId)/upload", method: "POST", body: body, headers: header, formData: nil)
    }
        
    static let closeChangeset = { (changesetId: String, workspaceId: String, accessToken: String) in
        let header = [
            "Authorization": "Bearer \(accessToken)",
            "X-Workspace": workspaceId,
            "Content-Type": "application/xml"
        ]
        return APIEndpoint(path: "/changeset/\(changesetId)/close", method: "PUT", body: nil, headers: header, formData: nil)
    }
    static let fetchuserProfile = { (userName: String, accessToken: String) in
        
        let header = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type":"application/json"
        ]
        
        return APIEndpoint(path: "/user-profile?user_name=\(userName)", method: "GET", body: nil, headers: header, formData: nil) }
    
    static let createKartaViewSequence = { (formData: [[String: Any]]) in
        return APIEndpoint(path: "/sequence/", method: "POST", body: nil, headers: nil, formData: formData)
    }
    
    static let uploadPhotoToKartaview = {(formData: [[String: Any]]) in
        return APIEndpoint(path: "/photo/", method: "POST", body: nil, headers: nil, formData: formData)
    }
    
    static let fetchPhotoUrlFromKartaview = { (formData: [[String: Any]]) in
        let queryItems: [URLQueryItem] = formData.compactMap { entry in
            guard let key = entry["key"] as? String, let value = entry["value"] else { return nil }
            return URLQueryItem(name: key, value: "\(value)")
        }
        var components = URLComponents()
        components.queryItems = queryItems
        let query = components.percentEncodedQuery.map { "?\($0)" } ?? ""
        return APIEndpoint(path: "/photo/" + query, method: "GET", body: nil, headers: nil, formData: nil)
    }
    
    static let finshedUploadingToKartaview = { (formData: [[String: Any]]) in
        return APIEndpoint(path: "/sequence/finished-uploading/", method: "POST", body: nil, headers: nil, formData: formData)
    
    }
    
    static let submitNote = { (note: String, accessToken: String, lat: Double, long: Double, workspaceId: String) in
        let header = [
            "Authorization": "Bearer \(accessToken)",
            "X-Workspace": workspaceId,
            "Content-Type": "application/json"
        ]
        let body = [
            "lat" : lat,
            "lon" : long,
            "text" : note
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: body, options: [])
        return APIEndpoint(path: "/notes.json", method: "POST", body: jsonData, headers: header, formData: nil)
        
    }
}

