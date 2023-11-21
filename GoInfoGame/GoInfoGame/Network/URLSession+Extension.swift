//
//  URLSession+Extension.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 20/11/23.
//

import Foundation


protocol NetworkRequest {
    func performRequest(url: URL, completion: @escaping (Result<Data, Error>) -> Void)
}


extension URLSession: NetworkRequest {
    func performRequest(url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        let task = dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
            } else if let data = data {
                completion(.success(data))
            } else {
                let unknownError = NSError(domain: "com.taskar.GoInfoGame", code: 0, userInfo: nil)
                completion(.failure(unknownError))
            }
        }
        task.resume()
    }
}

