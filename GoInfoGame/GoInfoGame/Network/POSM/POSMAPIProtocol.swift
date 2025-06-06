//
//  POSMAPIProtocol.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 24/05/25.
//

import osmapi

protocol POSMAPIProtocol {
    func fetchOSMElements(left: Double, bottom: Double, right: Double, top: Double, completion: @escaping (Result<OSMMapDataResponse, APIError>) -> Void)
    
    func openChangeset(osmPayload: Data?, workspaceId: String, completion: @escaping (Result<Int, APIError>) -> Void)
    
    func uploadChangeset(changesetBody: Data?, changesetId: String, completion: @escaping (Result<String, APIError>) -> Void)
    
    func closeChangeset(changesetId: String, completion: @escaping (Result<Bool, APIError>) -> Void)
    
    func fetchWay(wayId: String, completion: @escaping (Result<OSMWayResponse, APIError>) -> Void)
    
    func fetchNode(nodeId: String, completion: @escaping (Result<OSMNodeResponse, APIError>) -> Void)
    
    func submitNote(note: String, lat: Double, long: Double, completion: @escaping (Result<Bool, APIError>) -> Void)
    
}
