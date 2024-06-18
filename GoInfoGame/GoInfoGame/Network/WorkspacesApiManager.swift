//
//  WorkspacesApiManager.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 4/1/24.
//

import Foundation
// Singleton object that deals with workspaces APIs

class WorkspacesApiManager {
    
    static let shared = WorkspacesApiManager()
    private let listingURL = "https://waylyticsosm.blob.core.windows.net/flows/workspaces-test/uwdataset.json"
    private init() {}
    
    // fetches the workspaces based on latitiude and longitude
    func fetchWorkspaces(lat: String, lon: String, completion: @escaping (Result<[Workspace], Error>) -> Void) {
        var request = URLRequest(url: URL(string: self.listingURL)!, timeoutInterval: Double.infinity)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.failure(NSError(domain: "Data is nil", code: -1, userInfo: nil)))
                }
                return
            }

            let theDecoder = JSONDecoder()
            theDecoder.dateDecodingStrategy = .iso8601
            do {
                let workspaces = try theDecoder.decode([Workspace].self, from: data)
                completion(.success(workspaces))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
