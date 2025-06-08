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

enum WorkspaceContent: Equatable {
    case workspaces


    var loadingMessage: String {
        switch self {
        case .workspaces: "Fetching Workspaces..."
        }
    }
}

typealias WorkspaceState = ViewModelState<WorkspaceContent>

// WorkspacesViewModel - ViewModel for managing data related to initial view
class WorkspacesViewModel: ObservableObject {
    
    private var locationTracker: LocationTrackerProtocol
    
    @Published var workspaces: [Workspace] = []
    @Published var longQuests: [LongFormElement] = []
    
    private let api: WorkspaceAPIProtocol
    
    @Published var state: WorkspaceState = .idle
    
    var isPreview: Bool = false
    
    @Published var popupError: String?
    
    @Published var route: NavigationRoute?
    @Published var isLoadingQuests: Bool = false
    
    init(api: WorkspaceAPIProtocol = WorkspaceAPIManager.shared, locationTracker: LocationTrackerProtocol = LocationManagerDelegate(), state: WorkspaceState = .idle) {
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
        state = .loading(.workspaces)
    
            api.fetchWorkspaces { [weak self] result in
                DispatchQueue.main.async {
                    self?.state = .loaded(.workspaces)
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
    
    func fetchLongQuestsFor(workspace: Workspace) {
        isLoadingQuests = true
        api.fetchLongQuestsFor(workspaceId: "\(workspace.id)") { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let longQuestsResponse):
                    // Validate quest query
                    do {
                        for item in longQuestsResponse.elements {
                            _ = try item.questQuery.toElementFilterExpression()
                        }
                    } catch {
                        print("Invalid quest filter: \(error)")
                        self?.isLoadingQuests = false
                       self?.popupError = "Invalid quest filter"
                        return
                    }
                    self?.longQuests = longQuestsResponse.elements
                    self?.saveLongQuestsToDefaults(longQuestJson: longQuestsResponse.elements)
                    // Add one generic form for each longquest
                    QuestsRepository.shared.allQuests.removeAll()
                    for (index, quest) in longQuestsResponse.elements.enumerated() {
                        let applicableQuest = ApplicableQuest(
                            quest: LongElementQuest(
                                questId: "\(index + 1)",
                                questQuery: quest.questQuery,
                                elementType: quest.elementType,
                                elementTypeIcon: quest.elementTypeIcon
                            ),
                            questId: "\(index + 1)"
                        )
                        QuestsRepository.shared.allQuests.append(applicableQuest)
                    }
                    self?.isLoadingQuests = false
                    self?.route = .map(workspace: workspace)
                case .failure(let error):
                    print("ERROR FOR LONG FORM JSON IS ----?>>>>>>\(error.localizedDescription)")
                    self?.isLoadingQuests = false
                    if error.localizedDescription.contains("empty") {
                        self?.popupError = "No longform quests configured for this workspace."
                    } else {
                        self?.popupError = "Unable to load quests. (invalid JSON)"
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
