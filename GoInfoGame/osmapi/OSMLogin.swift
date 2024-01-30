//
//  OSMLogin.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/21/24.
//

import Foundation
public struct OSMLogin {
    let username: String
    let password: String
    
    // Header information needed
    func getHeaderData() -> String {
        let loginString = "\(username):\(password)"
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        return base64LoginString
    }
    
    public static var production : OSMLogin {
         OSMLogin(username: "nerope1097@wentcity.com", password: "$$WentCityErwin")
    }
    
    public static var test : OSMLogin {
        OSMLogin(username: "nareshd@vindago.in", password: "a$hwa7hamA") // Need to change
    }
}
