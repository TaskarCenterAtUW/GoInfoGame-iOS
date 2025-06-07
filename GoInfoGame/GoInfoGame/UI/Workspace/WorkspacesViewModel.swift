//
//  WorkspacesViewModel.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 03/04/24.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation
// WorkspacesViewModel - ViewModel for managing data related to initial view
class WorkspacesViewModel: ObservableObject {
    
    private var locationTracker: LocationTrackerProtocol
    
    @Published var workspaces: [Workspace] = []
    @Published var longQuests: [LongFormElement] = []
    
    private let api: WorkspaceAPIProtocol
    
    @Published var state: ViewModelState = .idle
    
    var isPreview: Bool = false
    
    init(api: WorkspaceAPIProtocol = WorkspaceAPIManager.shared, locationTracker: LocationTrackerProtocol = LocationManagerDelegate(), state: ViewModelState = .idle) {
        self.api = api
        self.locationTracker = locationTracker
        self.state = state
    }
    
    func enableLocationTracking() {
        guard !isPreview else {
            print("Skipping location tracking in preview")
            return
        }
        locationTracker.startTracking()
        
        locationTracker.locationUpdateHandler = { [weak self] coordinate in
            print("Location updated: \(coordinate)")
                self?.fetchWorkspacesList()
            }
    }
    
    func disableLocationTracking() {
        locationTracker.stopTracking()
    }
    
    // fetch workspaces list
    func fetchWorkspacesList() {
        print("STARTING TO FETCH WORKSPACES")
            state = .loading
    
            api.fetchWorkspaces { [weak self] result in
                DispatchQueue.main.async {
                    self?.state = .loaded
                    switch result {
                    case .success(let workspacesResponse):
                        self?.workspaces = workspacesResponse
                       
                    case .failure(let error):
                        self?.state = .error(error.localizedDescription)
                        print("Error fetching workspaces: \(error)")
                      
                    }
                }
            }
    }
    
    func checkAndDeleteWorkspaceDB(workspaceId: String) {
        if let existingWorkspaceId = KeychainManager.load(key: "workspaceID") {
            if existingWorkspaceId != workspaceId {
                print("User is changing the workpace. Delete all existing data from DB")
                DatabaseConnector.shared.clearDB()
            }
        }
    }
    
    func fetchLongQuestsFor(workspaceId: String,completion: @escaping (Bool, String?) -> Void) {
        
        state = .loading
        
        api.fetchLongQuestsFor(workspaceId: workspaceId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .success(let longQuestsResponse):
                    do {
                        for item in longQuestsResponse {
                            _ = try item.questQuery.toElementFilterExpression()
                        }
                    } catch {
                        print("Invalid quest filter: \(error)")
                        self.state = .error("Invalid quest filter expression.")
                        completion(false, "Invalid quest query.")
                        return
                    }

                    self.longQuests = longQuestsResponse
                    self.saveLongQuestsToDefaults(longQuestJson: longQuestsResponse)

                    for (index, quest) in self.longQuests.enumerated() {
                        let applicableQuest = ApplicableQuest(
                            quest: LongElementQuest(
                                questId: "\(index + 1)",
                                questQuery: quest.questQuery,
                                elementType: quest.elementType, elementTypeIcon: quest.elementTypeIcon
                            ),
                            questId: "\(index + 1)"
                        )

                        QuestsRepository.shared.allQuests.append(applicableQuest)
                    }

                    self.state = .loaded
                    completion(true, nil)

                case .failure(let error):
                    print("ERROR FOR LONG FORM JSON IS ----?>>>>>>\(error.localizedDescription)")
                    self.state = .error(error.localizedDescription)
                    if error.localizedDescription.contains("empty") {
                        completion(false, "Please configure longform.")
                    } else {
                        completion(false, "Unable to load quests.(invalid JSON)")
                    }
                }
            }
        }
    }
    
    
    func saveLongQuestsToDefaults(longQuestJson: [LongFormElement]) {
        do {
           try FileStorageManager.shared.save(questModels: longQuestJson, to: "longQuestJson")
        } catch {
            print("Failed to save file: \(error)")
        }
    }
}
