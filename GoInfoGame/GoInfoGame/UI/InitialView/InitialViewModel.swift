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
    @Published var workspaces: [Workspace] = [] 
    @Published var longQuests: [LongFormModel] = []
    @Published var isLoading: Bool = false
    
    @Published var shouldShowBiometricOptInPrompt = false
    @Published var showBiometricIDError: Bool = false
    @Published var biometricIDErrorMessage: String?

    
    init() {
        locationManagerDelegate.locationManager.delegate = locationManagerDelegate
        locationManagerDelegate.locationManager.requestWhenInUseAuthorization()
        locationManagerDelegate.locationManager.startUpdatingLocation()
        
        locationManagerDelegate.locationUpdateHandler = { [weak self] location in
            guard let self = self else { return }
            // fetch workspace
           // fetchWorkspaceFor(currentLocation: location)
            fetchWorkspacesList()
        }
    }
    
    func checkBiometricOptInCondition() {
          let env = APIConfiguration.shared.environment
          let useBiometricID = UserDefaults.standard.bool(forKey: "useBiometricID")
          let biometricOptInDeclined = UserDefaults.standard.bool(forKey: "biometricOptInDeclined")

          if !useBiometricID && !biometricOptInDeclined,
             KeychainManager.load(.username, for: env) != nil,
             SessionManager.shared.lastLoginPassword != nil {
              shouldShowBiometricOptInPrompt = true
          }
      }
    
    
    
    // fetch workspaces list
    func fetchWorkspacesList() {
                
        if let accessToken = KeychainManager.load(key: "accessToken") {
            ApiManager.shared.performRequest(to: .fetchWorkspaceList(accessToken), setupType: .workspace, modelType: [Workspace].self) { result in
            
            DispatchQueue.main.async {
                switch result {
                case .success(let workspacesResponse):
                    self.workspaces = workspacesResponse
                    self.isLoading = false
                case .failure(let error):
                    print("Error fetching workspaces: \(error)")
                    self.isLoading = false
                }
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
        
        ApiManager.shared.performRequest(to: .fetchLongQuests(workspaceId), setupType: .workspace, modelType: [LongFormModel].self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let longQuestsResponse):
                    
                    // Validate quest query
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
                    
                    // Add one generic form for each longquest
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
    
    
    func saveLongQuestsToDefaults(longQuestJson: [LongFormModel]) {
        do {
           try FileStorageManager.shared.save(questModels: longQuestJson, to: "longQuestJson")
        } catch {
            print("Failed to save file: \(error)")
        }
    }
    
    func userAcceptedBiometricOptIn() {
        UserDefaults.standard.setValue(true, forKey: "useBiometricID")
        UserDefaults.standard.setValue(false, forKey: "biometricOptInDeclined")
        SessionManager.shared.savePasswordForBiometric()
    }

    func userDeclinedBiometricOptIn() {
        UserDefaults.standard.setValue(true, forKey: "biometricOptInDeclined")
    }

}
