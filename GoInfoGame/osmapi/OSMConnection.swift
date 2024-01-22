//
//  OSMConnection.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/21/24.
//

import Foundation
class OSMConnection {
    // Creates a connection
    let baseUrl: String = OSMConfig.baseUrl
    
    var currentChangesetId: Int? = 0
    
//    let userCreds: OSMLogin = OSMLogin(username: "nareshd@vindago.in", password: "a$hwa7hamA")
    let userCreds: OSMLogin = OSMLogin(username: "nareshd@gaussiansolutions.com", password: "ycqzd3_F6rqDEhs")
    //ycqzd3_F6rqDEhs / nareshd@gaussiansolutions.com
    
    // Lets see if we can start with some authentication or node
    
    func getNode(id: String,_ completion: @escaping (Result<OSMNodeResponse, Error>)-> Void) {
        let urlString = self.baseUrl.appending("node/").appending(id).appending(".json")
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
                    return
                }
        BaseNetworkManager.shared.fetchData(url: url, completion: completion) // Need to improve this one
    }
    
    func getWay(id: String,_ completion: @escaping (Result<OSMWayResponse, Error>)-> Void) {
        let urlString =  self.baseUrl.appending("way/").appending(id).appending(".json")
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
                    return
                }
        BaseNetworkManager.shared.fetchData(url: url, completion: completion) // Need to improve this one
    }
    
    func openChangeSet(_ completion: @escaping((Result<Int,Error>)->Void)) {
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
    
    func closeChangeSet(id: String,completion: @escaping((Result<Bool,Error>)->Void)) {
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
    
    // Original method with everything from postman
    func getChangesets(_ completion: @escaping(()->())) {
        
        var request = URLRequest(url: URL(string: "https://waylyticsposm.westus2.cloudapp.azure.com/api/0.6/changesets.json")!,timeoutInterval: Double.infinity)
        request.addValue("Basic bmFyZXNoZEB2aW5kYWdvLmluOmEkaHdhN2hhbUE=", forHTTPHeaderField: "Authorization")

        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
          guard let data = data else {
            print(String(describing: error))
              completion()
            return
          }
          print(String(data: data, encoding: .utf8)!)
            completion()
        }

        task.resume()
    }
    
    // Updated method
    func getChangesets2(completion: @escaping (Result<OSMChangesetResponse, Error>)->Void) {
        // Get the base URL
        let urlString = self.baseUrl.appending("changesets.json")
        guard let url = URL(string: urlString) else {
            print("Invalid URL given")
                    return
                }
        // Get to work
        BaseNetworkManager.shared.addOrSetHeaders(header: "Authorization", value: "Basic \(self.userCreds.getHeaderData())")
        BaseNetworkManager.shared.fetchData(url: url, completion: completion)
    }
    
    
}
