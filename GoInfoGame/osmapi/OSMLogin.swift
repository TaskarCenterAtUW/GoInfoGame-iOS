//
//  OSMLogin.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/21/24.
//

import Foundation
/// Structure to store the user credentials
public struct OSMLogin {
    /// user name
    let username: String
    /// the password
    let password: String
    
    /// Fetches the header information to be added
    /// - returns String
    func getHeaderData() -> String {
        let loginString = "\(username):\(password)"
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        return base64LoginString
    }
    
    /// Production credentials
    public static var production : OSMLogin {
         OSMLogin(username: "nerope1097@wentcity.com", password: "$$WentCityErwin")
    }
    
    /// Test server credentials
    public static var test : OSMLogin {
        OSMLogin(username: "nareshd@vindago.in", password: "a$hwa7hamA") // Need to change
    }
    /// Dev server credentials
    public static var testOSM : OSMLogin {
        OSMLogin(username: "giyiw35819@tupanda.com", password: "d.Dgq6J6aBy.dCJ") 
    }
}
