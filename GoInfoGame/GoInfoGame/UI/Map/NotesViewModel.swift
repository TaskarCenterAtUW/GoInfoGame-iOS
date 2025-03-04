//
//  NotesViewModel.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 04/03/25.
//

import Foundation


class NotesViewModel: ObservableObject {
    
    @Published var isLoading = false
    
    init() {}
    
    func createNote(note: String, lat: Double, long: Double) async throws -> Bool {
        
        await MainActor.run {
            self.isLoading = true
        }
        
        guard let workspaceId = KeychainManager.load(key: "workspaceID") else {
            throw NSError(domain: "NoAccessToken", code: 0, userInfo: [NSLocalizedDescriptionKey: "Workspace Error"])
        }
        
        guard let accessToken = KeychainManager.load(key: "accessToken") else {
            throw NSError(domain: "NoAccessToken", code: 0, userInfo: [NSLocalizedDescriptionKey: "No Access Token found"])
        }
        
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            ApiManager.shared.performRequest(to: .composeNote(note, accessToken, lat, long, workspaceId), setupType: .osm, modelType: String.self, useJSON: false) { result in
                Task { @MainActor in
                    self?.isLoading = false
                }
                
                switch result {
                case .success(_):
                    continuation.resume(returning: true)
                case .failure(let failure):
                    continuation.resume(throwing: failure)
                }
            }
        }
    }
}

