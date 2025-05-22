//
//  APIRequest.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 23/05/25.
//

import Foundation

struct APIRequest {
    let path: String
    let method: String
    let headers: [String: String]?
    let body: Data?
    let formData: [[String: Any]]?
    let useJSON: Bool

    init(
        path: String,
        method: String,
        headers: [String: String]? = nil,
        body: Data? = nil,
        formData: [[String: Any]]? = nil,
        useJSON: Bool = true
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.body = body
        self.formData = formData
        self.useJSON = useJSON
    }
}
