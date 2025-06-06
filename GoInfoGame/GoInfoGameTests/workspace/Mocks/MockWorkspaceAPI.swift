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
    var returnedLongQuests: [LongFormModel]
    
    var didCallFetchWorkspaces = false
    var didCallFetchLongQuests = false
    
    init(
        shouldSucceed: Bool = true,
        returnedWorkspaces: [Workspace] = [],
        returnedLongQuests: [LongFormModel] = []
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
    
    func fetchLongQuestsFor(workspaceId: String, completion: @escaping (Result<[LongFormModel], APIError>) -> Void) {
        didCallFetchLongQuests = true
        if shouldDeferCompletion {
            return
        }
        if shouldSucceed {
            completion(.success(returnedLongQuests))
        } else {
            completion(.failure(.notFound("Not found")))
        }
    }
}
