//
//  OSMConnection.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/21/24.
//

import Foundation

/**
 Base class that deals with all the interactions with OSM server
 */
public class OSMConnection {
    // Creates a connection
    let baseUrl: String
    var currentChangesetId: Int? = 0
    
    var userCreds: OSMLogin {
        if baseUrl.contains("workspace") {
            return OSMLogin.workspaceUser
        } else {
            return OSMLogin.osmUser
        }
    }
    
    // AuthToken
   public var accessToken: String? = nil
    
    
    var authorizationValue: String {
        
        return "Bearer \(accessToken!)"
        
        
//        if baseUrl.contains("workspaces") {
//            return "Basic \(userCreds.getHeaderData())"
//        } else {
//            guard let accessToken = accessToken else {
//                fatalError("Access token not available.")
//            }
//            
//            return "Bearer \(accessToken)"
//        }
    }

    /// Initializer for OSMConnection
    /// - parameter config : The Server configuration (defaults to OSMConfig.testOSM)
    /// - parameter currentChangesetId: The overal changeset id for the user
    /// - parameter userCreds: User credentials for authenticated calls. Defaults to testOSM
    public init(config: OSMConfig = OSMConfig.testPOSM, currentChangesetId: Int? = nil) {
        self.baseUrl = config.baseUrl
        self.currentChangesetId = currentChangesetId
        
     
       if let token = KeychainManager.load(key: "accessToken") {
           self.accessToken = token
        }
    }
    /// Fetches a single node
    /// - parameter id : the `id` of the node
    /// - parameter completion: The completion handler that receives the node
    func getNode(id: String,_ completion: @escaping (Result<OSMNodeResponse, Error>)-> Void) {
        //TODO: Write error when node does not exist
        let urlString = self.baseUrl.appending("node/").appending(id).appending(".json")
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
            return
        }
        BaseNetworkManager.shared.addOrSetHeaders(header: "Authorization", value: authorizationValue)
        // Bearer
        BaseNetworkManager.shared.fetchData(url: url, completion: completion) // Need to improve this one
    }
    /// Fetches a single way
    /// - parameter id: the `id` of the way
    /// - parameter completion: The completion handler that receives the way
    func getWay(id: String,_ completion: @escaping (Result<OSMWayResponse, Error>)-> Void) {
        //TODO: Write errors when way does not exist
        let urlString =  self.baseUrl.appending("way/").appending(id).appending(".json")
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
            return
        }
        BaseNetworkManager.shared.addOrSetHeaders(header: "Authorization", value: authorizationValue)
        BaseNetworkManager.shared.fetchData(url: url, completion: completion) // Need to improve this one
    }
    
    /// Opens a changeset for the given user
    /// - parameter completion: Completion handler that receives the newly opened changesetId
    public func openChangeSet(createdByTag: String, _ completion: @escaping((Result<Int,Error>)->Void)) {
        //TODO: Write errors when not authenticated and if there is already an open changeset with same user
        let urlString1 = self.baseUrl.appending("changeset/create")
        let urlString = "https://osm.workspaces-stage.sidewalks.washington.edu/api/0.6/changeset/create"
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
            return
        }
       // let workspaceID = KeychainManager.load(key: "workspaceID")
        BaseNetworkManager.shared.addOrSetHeaders(header: "Authorization", value: "Bearer \(accessToken!)")
        BaseNetworkManager.shared.postData(url: url,method: "PUT" ,body: OSMChangesetPayload(createdByTag: createdByTag)) { (result: Result<Int,Error>) in
            switch result {
            case .success(let changesetID):
                print("CHANGESET ID ===>\(changesetID)")
                self.currentChangesetId = changesetID
                
            case .failure(let error):
                print(error)
            }
            completion(result)
        }
    }
    /// Closes the changeset
    /// - parameter id: The changeset ID to be closed
    /// - parameter completion: The completion handler
    public func closeChangeSet(id: String,completion: @escaping((Result<Bool,Error>)->Void)) {
        //TODO: Write error codes if not able to close
        let urlString = self.baseUrl.appending("changeset/").appending(id).appending("/close")
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
            return
        }
        BaseNetworkManager.shared.addOrSetHeaders(header: "Authorization", value: authorizationValue)
        BaseNetworkManager.shared.postData(url: url,method: "PUT" ,body: ["tag":"xyz"],expectEmpty: true) { (result: Result<Bool,Error>) in
            switch result {
            case .success(let closedResult):
                print(id)
                print(closedResult)
                
            case .failure(let error):
                print(error)
            }
            completion(result)
        }
    }
    
    // TODO: We are not using this any where, need to discuss and remove it.
    // Original method with everything from postman
    func getChangesets(_ completion: @escaping(()->())) {
        let urlString = self.baseUrl.appending("changesets.json")
        var request = URLRequest(url: URL(string: urlString)!,timeoutInterval: Double.infinity)
        request.addValue(authorizationValue, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion()
                return
            }
            completion()
        }
        task.resume()
    }
    
    // Updated method
    func getChangesets2(completion: @escaping (Result<OSMChangesetResponse, Error>)->Void) {
        // Get the base URL
        let urlString = self.baseUrl.appending("changesets.json?open=true")
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
            return
        }
        // Get to work
        BaseNetworkManager.shared.addOrSetHeaders(header: "Authorization", value: authorizationValue)
        BaseNetworkManager.shared.fetchData(url: url, completion: completion)
    }
    
    /// Updates a single node
    /// - parameter node : An instance of `OSMNode`
    /// - parameter tags: A `[String:String]` dictionary containing new added tags
    /// - parameter completion : A handler that is called after the call is made
    public func updateNode(node: inout OSMNode, tags:[String:String], completion: @escaping((Result<Int,Error>)->Void)){
        //TODO: Error handling when there is no active changeset, no node and not authorized
        let urlString = self.baseUrl.appending("node/").appending(String(node.id))
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
            return
        }
        BaseNetworkManager.shared.addOrSetHeaders(header: "Authorization", value: authorizationValue)
        // Add nodes to the same
        if(node.tags == nil){
            node.tags = [:]
        }
        tags.forEach { (key: String, value: String) in
            
            node.tags[key] = value
        }
        // Make the call
        BaseNetworkManager.shared.postData(url: url, method: "PUT",body: node ,completion: completion)
        
    }
    /// Updates a single way
    /// - parameter way: the current way element
    /// - parameter tags: `[String:String]` dictionary containing new tags
    /// - parameter completion: The completion handler after this is done
    public func updateWay(way: inout OSMWay, tags:[String:String], completion: @escaping((Result<Int,Error>)->Void)){
        //TODO: Error handling when there is no active changeset, way not found and not authorized
        let urlString = self.baseUrl.appending("way/").appending(String(way.id))
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
            return
        }
        BaseNetworkManager.shared.addOrSetHeaders(header: "Authorization", value: authorizationValue)
        // Add nodes to the same
        
        tags.forEach { (key: String, value: String) in
            way.tags[key] = value
        }
        // Make the call
        BaseNetworkManager.shared.postData(url: url, method: "PUT",body: way ,completion: completion)
        
    }
    
    /// Fetches the user details based on `id`
    /// - parameter id : Id of the user
    /// - parameter completion : Completion handler with user data response
    func getUserDetailsWithId(id: String,_ completion: @escaping (Result<OSMUserDataResponse, Error>)-> Void) {
        //TODO: Error for user id not found
        let urlString =  self.baseUrl.appending("user/").appending(id).appending(".json")
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
            return
        }
        BaseNetworkManager.shared.fetchData(url: url, completion: completion)
    }
    
    /// Fetches the user details based on 'access token'
    /// - parameter token: access token of the logged in user
    /// - parameter completion : Completion handler with user data response
    public func getUserDetailsWithToken(accessToken: String, _ completion:@escaping (Result<OSMUserDataResponse, Error>)-> Void) {
        //TODO: Error for user id not found
        let urlString =  self.baseUrl.appending("user/details.json")
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
            return
        }
        BaseNetworkManager.shared.addOrSetHeaders(header: "Authorization", value: authorizationValue)
        BaseNetworkManager.shared.fetchData(url: url, completion: completion)
    }
    
    /// Fetches the current logged in user details
    /// - parameter completion : Completion handler
    public func getUserDetails(_ completion: @escaping (Result<OSMUserDataResponse, Error>)-> Void) {
        //TODO: Errors for unauthenticated call
        let urlString =  self.baseUrl.appending("user/details.json")
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
            return
        }
        BaseNetworkManager.shared.addOrSetHeaders(header: "Authorization", value: authorizationValue)
        BaseNetworkManager.shared.fetchData(url: url, completion: completion)
    }
    
//    /// Internal function for getting the map data
//     public func getOSMMapData(left: Double, bottom: Double, right: Double, top: Double,_ completion: @escaping (Result<OSMMapDataResponse, Error>)-> Void) {
//         let urlString =  self.baseUrl.appending("map.json?bbox=\(left),\(bottom),\(right),\(top)")
//        print(urlString)
//        guard let url = URL(string: urlString) else {
//            print("Invalid URL given")
//                    return
//                }
//         if let workspaceID = KeychainManager.load(key: "workspaceID") {
//             BaseNetworkManager.shared.addOrSetHeaders(header: "X-Workspace", value: workspaceID)
//         }
//        BaseNetworkManager.shared.fetchData(url: url, completion: completion)
//    }
    
//    /// Function used to get the map data and give it in the form of a dictionary with Integers as ids and elements in the right side.
//    public func fetchMapData(left: Double, bottom: Double, right: Double, top: Double,_ completion: @escaping (Result<[Int:OSMElement], Error>)-> Void){
//        getOSMMapData(left: left, bottom: bottom, right: right, top: top) { result in
//            switch result {
//            case .success(let osmResponse):
//                print("Convert nodes etc")
//                completion(.success(osmResponse.getOSMElements()))
//            case .failure(let error):
//                print("Bad result")
//                completion(.failure(error))
//            }
//            
//        }
//        
//    }
    
}
