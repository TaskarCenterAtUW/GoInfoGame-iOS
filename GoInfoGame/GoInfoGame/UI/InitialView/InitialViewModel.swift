//
//  InitialViewModel.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 03/04/24.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation
import LocalAuthentication
// InitialViewModel - ViewModel for managing data related to initial view
@MainActor
class InitialViewModel: ObservableObject {
    let locationManagerDelegate = LocationManagerDelegate()
    @Published var workspaces: [Workspace]? = nil
    @Published var longQuests: [LongFormElement] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    @Published var showBiometricIDError: Bool = false
    @Published var biometricIDErrorMessage: String?
    private(set) var currentLocation: CLLocationCoordinate2D?

    
    init() {
        locationManagerDelegate.locationUpdateHandler = { [weak self] location in
            guard let self = self else { return }
            self.currentLocation = location
            fetchWorkspacesList(location: location)
            locationManagerDelegate.stopUpdatingLocation()
        }
        
        locationManagerDelegate.requestLocationAuthorization()
        locationManagerDelegate.startUpdatingLocation()
    }

    // fetch workspaces list
    func fetchWorkspacesList(location: CLLocationCoordinate2D) {
        self.isLoading = true
        if let accessToken = KeychainManager.load(key: "accessToken") {
            ApiManager.shared.performRequest(to: .fetchWorkspaceList(location, 20000, true, accessToken), setupType: .workspace, modelType: [Workspace].self) { result in
            
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                switch result {
                case .success(let workspacesResponse):
                    self?.workspaces = workspacesResponse
                    self?.errorMessage = nil
                case .failure(let error):
                    self?.workspaces = nil
                    self?.errorMessage = error.localizedDescription
                    print("Error fetching workspaces: \(error)")
                }
            }
        }
    }
    }
    
    func checkAndDeleteWorkspaceDB(workspaceId: String) {
        isLoading = true
        if let existingWorkspaceId = KeychainManager.load(key: "workspaceID") {
            if existingWorkspaceId != workspaceId {
                print("User is changing the workpace. Delete all existing data from DB")
                DatabaseConnector.shared.clearDB()
            }
        }
        isLoading = false
        
    }
    
    func fetchLongQuestsFor(workspaceId: String,completion: @escaping (Bool, String?) -> Void) {
        
        isLoading = true
        
        ApiManager.shared.performRequest(to: .fetchLongQuests(workspaceId), setupType: .workspace, modelType: LongFormResponse.self) { [weak self] result in
            guard let self = self else { return completion(false, "Object memory released.") }
            DispatchQueue.main.async { [unowned self] in
                switch result {
                case .success(let longQuestsResponse):
                    
                    // Validate quest query
                    do {
                        for item in longQuestsResponse.elements {
                                _ = try item.questQuery.toElementFilterExpression()
                            }
                        } catch {
                            print("Invalid quest filter: \(error)")
                            self.isLoading = false
                            completion(false, "Invalid quest query.")
                            return
                        }

                    self.longQuests = longQuestsResponse.elements
                    self.saveLongQuestsToDefaults(longQuestJson: longQuestsResponse.elements)
                    
                    // Add one generic form for each longquest
                    QuestsRepository.shared.allQuests.removeAll()
                    for (index, quest) in self.longQuests.enumerated() {
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

                    self.isLoading = false
                    completion(true, "")
                case .failure(let error):
                    print("ERROR FOR LONG FORM JSON IS ----?>>>>>>\(error.localizedDescription)")
                    self.isLoading = false
                    if error.localizedDescription.contains("empty") {
                        completion(false, "Please configure longform." )
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
