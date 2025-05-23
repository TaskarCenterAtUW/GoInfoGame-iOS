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
        
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            POSMAPIManager.shared.submitNote(note: note, lat: lat, long: long) { result in
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

