//
//  TDEIAPIProtocol.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 24/05/25.
//

protocol TDEIAPIProtocol {
    func login(username: String, password: String, completion: @escaping (Result<PosmLoginSuccessResponse, APIError>) -> Void)
    
    func refreshToken(refreshToken: String, completion: @escaping (Result<PosmLoginSuccessResponse, APIError>) -> Void)
    
    func fetchUserProfile(completion: @escaping (Result<TdeiUserProfile, APIError>) -> Void)

}
