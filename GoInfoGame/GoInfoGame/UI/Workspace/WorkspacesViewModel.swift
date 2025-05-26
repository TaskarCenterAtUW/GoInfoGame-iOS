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
    private var locationService: LocationServiceProtocol
    
    @Published var workspaces: [Workspace] = []
    @Published var longQuests: [LongFormModel] = []
    @Published var isLoading: Bool = false
    
    private let api: WorkspaceAPIProtocol
    
    init(api: WorkspaceAPIProtocol = WorkspaceAPIManager.shared, locationService: LocationServiceProtocol = LocationManagerDelegate()) {
        self.api = api
        self.locationService = locationService
    }
    
    func enableLocationTracking() {
        locationService.requestLocationAuthorization()
        locationService.startUpdatingLocation()
        locationService.locationUpdateHandler = { [weak self] coordinate in
            self?.fetchWorkspacesList()
        }
    }
    
    func disableLocationTracking() {
        locationService.stopUpdatingLocation()
    }
    
    // fetch workspaces list
    func fetchWorkspacesList() {
            isLoading = true
            api.fetchWorkspaces { [weak self] result in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    switch result {
                    case .success(let workspacesResponse):
                        self?.workspaces = workspacesResponse
                       
                    case .failure(let error):
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
        
        isLoading = true
        
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
                        self.isLoading = false
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
                                elementType: quest.elementType
                            ),
                            questId: "\(index + 1)"
                        )

                        QuestsRepository.shared.allQuests.append(applicableQuest)
                    }

                    self.isLoading = false
                    completion(true, nil)

                case .failure(let error):
                    print("ERROR FOR LONG FORM JSON IS ----?>>>>>>\(error.localizedDescription)")
                    self.isLoading = false
                    if error.localizedDescription.contains("empty") {
                        completion(false, "Please configure longform.")
                    } else {
                        completion(false, "Unable to load quests.(invalid JSON)")
                    }
                }
            }
        }
    }
    
    
    func saveLongQuestsToDefaults(longQuestJson: [LongFormModel]) {
        do {
           try FileStorageManager.shared.save(questModels: longQuestJson, to: "longQuestJson")
        } catch {
            print("Failed to save file: \(error)")
        }
    }
}
