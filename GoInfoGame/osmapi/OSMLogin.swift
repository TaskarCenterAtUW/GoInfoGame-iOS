//
//  OSMLogin.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/21/24.
//

import Foundation
struct OSMLogin {
    let username: String
    let password: String
    
    // Header information needed
    func getHeaderData() -> String {
        let loginString = "\(username):\(password)"
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        return base64LoginString
    }
}
