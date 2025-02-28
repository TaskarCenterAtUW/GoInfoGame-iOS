//
//  SyncLogger.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 28/02/25.
//

import Foundation

class SyncLogger {
    static let shared = SyncLogger()
    
    private init() {}

    func logStep(_ message: String) {
        print("➡️ \(message)")
    }
}
