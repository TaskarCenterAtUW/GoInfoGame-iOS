//
//  MockTDEIAPI.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 11/06/25.
//

import Foundation

@testable import GoInfoGame

final class MockTDEIAPI: TDEIAPIProtocol {
    
    var shouldSucceed = true
    var refreshCalled = false
    
    
    func login(username: String, password: String, completion: @escaping (Result<PosmLoginSuccessResponse, APIError>) -> Void) {
        
    }
    
    func refreshToken(refreshToken: String, completion: @escaping (Result<PosmLoginSuccessResponse, APIError>) -> Void) {
        refreshCalled = true
        
        

        
        
        
    }
    
    func fetchUserProfile(completion: @escaping (Result<TdeiUserProfile, APIError>) -> Void) {
        
    }
    
}

