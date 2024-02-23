//
//  OSMConnection.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/21/24.
//

import Foundation
public class OSMConnection {
    // Creates a connection
    let baseUrl: String
    var currentChangesetId: Int? = 0
    let userCreds: OSMLogin
    // Lets see if we can start with some authentication or node
    public init(config: OSMConfig = OSMConfig.testOSM, currentChangesetId: Int? = nil, userCreds: OSMLogin = OSMLogin.testOSM) {
        self.baseUrl = config.baseUrl
        self.currentChangesetId = currentChangesetId
        self.userCreds = userCreds
    }
    
    func getNode(id: String,_ completion: @escaping (Result<OSMNodeResponse, Error>)-> Void) {
        let urlString = self.baseUrl.appending("node/").appending(id).appending(".json")
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
            return
        }
        BaseNetworkManager.shared.addOrSetHeaders(header: "Authorization", value: "Basic \(self.userCreds.getHeaderData())")
        BaseNetworkManager.shared.fetchData(url: url, completion: completion) // Need to improve this one
    }
    
    func getWay(id: String,_ completion: @escaping (Result<OSMWayResponse, Error>)-> Void) {
        let urlString =  self.baseUrl.appending("way/").appending(id).appending(".json")
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
            return
        }
        BaseNetworkManager.shared.addOrSetHeaders(header: "Authorization", value: "Basic \(self.userCreds.getHeaderData())")
        BaseNetworkManager.shared.fetchData(url: url, completion: completion) // Need to improve this one
    }
    
    public func openChangeSet(_ completion: @escaping((Result<Int,Error>)->Void)) {
        // Have to open changeset
        let urlString = self.baseUrl.appending("changeset/create")
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
            return
        }
        BaseNetworkManager.shared.addOrSetHeaders(header: "Authorization", value: "Basic \(self.userCreds.getHeaderData())")
        BaseNetworkManager.shared.postData(url: url,method: "PUT" ,body: OSMChangesetPayload()) { (result: Result<Int,Error>) in
            switch result {
            case .success(let changesetID):
                print(changesetID)
                self.currentChangesetId = changesetID
                
            case .failure(let error):
                print(error)
            }
            completion(result)
        }
    }
    
    public func closeChangeSet(id: String,completion: @escaping((Result<Bool,Error>)->Void)) {
        let urlString = self.baseUrl.appending("changeset/").appending(id).appending("/close")
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
            return
        }
        BaseNetworkManager.shared.addOrSetHeaders(header: "Authorization", value: "Basic \(self.userCreds.getHeaderData())")
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
        request.addValue("Basic \(self.userCreds.getHeaderData())", forHTTPHeaderField: "Authorization")
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
        BaseNetworkManager.shared.addOrSetHeaders(header: "Authorization", value: "Basic \(self.userCreds.getHeaderData())")
        BaseNetworkManager.shared.fetchData(url: url, completion: completion)
    }
    
    
    public func updateNode(node: inout OSMNode, tags:[String:String], completion: @escaping((Result<Int,Error>)->Void)){
        // Have to do this.
        let urlString = self.baseUrl.appending("node/").appending(String(node.id))
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
            return
        }
        BaseNetworkManager.shared.addOrSetHeaders(header: "Authorization", value: "Basic \(self.userCreds.getHeaderData())")
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
    
    public func updateWay(way: inout OSMWay, tags:[String:String], completion: @escaping((Result<Int,Error>)->Void)){
        // Have to do this.
        let urlString = self.baseUrl.appending("way/").appending(String(way.id))
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
            return
        }
        BaseNetworkManager.shared.addOrSetHeaders(header: "Authorization", value: "Basic \(self.userCreds.getHeaderData())")
        // Add nodes to the same
        
        tags.forEach { (key: String, value: String) in
            way.tags[key] = value
        }
        // Make the call
        BaseNetworkManager.shared.postData(url: url, method: "PUT",body: way ,completion: completion)
        
    }
    func getUserDetailsWithId(id: String,_ completion: @escaping (Result<OSMUserDataResponse, Error>)-> Void) {
        let urlString =  self.baseUrl.appending("user/").appending(id).appending(".json")
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
            return
        }
        BaseNetworkManager.shared.fetchData(url: url, completion: completion)
    }
    func getUserDetails(_ completion: @escaping (Result<OSMUserDataResponse, Error>)-> Void) {
        let urlString =  self.baseUrl.appending("user/details.json")
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
            return
        }
        BaseNetworkManager.shared.addOrSetHeaders(header: "Authorization", value: "Basic \(self.userCreds.getHeaderData())")
        BaseNetworkManager.shared.fetchData(url: url, completion: completion)
    }
    
    /// Internal function for getting the map data
     public func getOSMMapData(left: Double, bottom: Double, right: Double, top: Double,_ completion: @escaping (Result<OSMMapDataResponse, Error>)-> Void) {
         let urlString =  self.baseUrl.appending("map.json?bbox=\(left),\(bottom),\(right),\(top)")
        print(urlString)
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
                    return
                }
        BaseNetworkManager.shared.fetchData(url: url, completion: completion)
    }
    
    /// Function used to get the map data and give it in the form of a dictionary with Integers as ids and elements in the right side.
    public func fetchMapData(left: Double, bottom: Double, right: Double, top: Double,_ completion: @escaping (Result<[Int:OSMElement], Error>)-> Void){
        getOSMMapData(left: left, bottom: bottom, right: right, top: top) { result in
            switch result {
            case .success(let osmResponse):
                print("Convert nodes etc")
                completion(.success(osmResponse.getOSMElements()))
            case .failure(let error):
                print("Bad result")
                completion(.failure(error))
            }
            
        }
        
    }
    
}
