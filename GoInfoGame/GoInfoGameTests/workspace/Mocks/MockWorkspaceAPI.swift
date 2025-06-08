//
//  MockWorkspaceAPI.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 27/05/25.
//

import Foundation
import CoreLocation
@testable import GoInfoGame

final class MockWorkspaceAPI: WorkspaceAPIProtocol {
    var shouldSucceed: Bool
    var shouldDeferCompletion = false
    var returnedWorkspaces: [Workspace]
    var returnedLongQuests: [LongFormElement]
    
    var didCallFetchWorkspaces = false
    var didCallFetchLongQuests = false
    
    var isLoadingQuests = false
    
    init(
        shouldSucceed: Bool = true,
        returnedWorkspaces: [Workspace] = [],
        returnedLongQuests: [LongFormElement] = []
    ) {
        self.shouldSucceed = shouldSucceed
        self.returnedWorkspaces = returnedWorkspaces
        self.returnedLongQuests = returnedLongQuests
    }
    
    func fetchWorkspaces(completion: @escaping (Result<[Workspace], APIError>) -> Void) {
        didCallFetchWorkspaces = true
        if shouldDeferCompletion {
            return
        }
        if shouldSucceed {
            completion(.success(returnedWorkspaces))
        } else {
            completion(.failure(.notFound("Not found")))
        }
    }
    
    func fetchLongQuestsFor(workspaceId: String, completion: @escaping (Result<LongFormResponse, APIError>) -> Void) {
        didCallFetchLongQuests = true
        isLoadingQuests = true
        if shouldDeferCompletion {
            return
        }

        if shouldSucceed {
            let response = LongFormResponse(version: "0.6", elements: returnedLongQuests)
            completion(.success(response))
        } else {
            completion(.failure(.custom("Mocked failure: Invalid JSON or other error")))
        }
    }

}
