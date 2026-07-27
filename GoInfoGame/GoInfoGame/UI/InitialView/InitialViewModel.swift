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

    @Published var searchText: String = ""
    // nil means "All project groups"
    @Published var selectedProjectGroupId: String? = nil
    // tdeiProjectGroupId -> project_group_name, fetched separately from /project-group-roles.
    @Published var projectGroupNamesById: [String: String] = [:]

    // Workspaces eligible to be shown/selected, before search/project-group filtering.
    var eligibleWorkspaces: [Workspace] {
        workspaces?.filter { $0.type == "osw" && $0.externalAppAccess == 1 } ?? []
    }

    // Unique tdeiProjectGroupIds available for the current workspaces, for the filter dropdown.
    var projectGroupIds: [String] {
        Array(Set(eligibleWorkspaces.compactMap { $0.tdeiProjectGroupId })).sorted()
    }

    // Workspaces after applying the selected project group and search text.
    var filteredWorkspaces: [Workspace] {
        var result = eligibleWorkspaces
        if let selectedProjectGroupId {
            result = result.filter { $0.tdeiProjectGroupId == selectedProjectGroupId }
        }
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSearch.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(trimmedSearch) }
        }
        return result
    }

    func clearFilters() {
        searchText = ""
        selectedProjectGroupId = nil
    }

    // Display name for the project group dropdown; falls back to the raw id if the
    // name hasn't loaded yet (or failed to load) so filtering still works either way.
    func projectGroupDisplayName(for groupId: String?) -> String {
        guard let groupId else { return "All" }
        return projectGroupNamesById[groupId] ?? groupId
    }

    init() {
        locationManagerDelegate.locationUpdateHandler = { [weak self] location in
            guard let self = self else { return }
            self.currentLocation = location
            fetchWorkspacesList(location: location)
            locationManagerDelegate.stopUpdatingLocation()
        }

        locationManagerDelegate.requestLocationAuthorization()
        locationManagerDelegate.startUpdatingLocation()
        fetchProjectGroupRoles()
    }

    // Fetches project group names so the dropdown can show human-readable names instead of raw ids.
    // Non-fatal on failure: the filter dropdown just falls back to showing the raw tdeiProjectGroupId.
    func fetchProjectGroupRoles() {
        guard let accessToken = KeychainManager.load(key: "accessToken"),
              let userId = JWTDecoder.subject(fromToken: accessToken) else {
            print("Unable to resolve user id from access token; project group filter will show raw ids.")
            return
        }

        ApiManager.shared.performRequest(to: .fetchProjectGroupRoles(userId, accessToken), setupType: .login, modelType: [ProjectGroupRole].self) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let roles):
                    self?.projectGroupNamesById = Dictionary(roles.map { ($0.tdeiProjectGroupId, $0.projectGroupName) }, uniquingKeysWith: { first, _ in first })
                case .failure(let error):
                    print("Error fetching project group roles: \(error)")
                }
            }
        }
    }

    // fetch workspaces list
    func fetchWorkspacesList(location: CLLocationCoordinate2D) {
        self.isLoading = true
        self.clearFilters()
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
    
    func fetchLongQuestsFor(workspaceId: String,completion: @escaping (Bool, String?, Workspace?) -> Void) {
        
        isLoading = true
        
        ApiManager.shared.performRequest(to: .fetchWorkspaceDetails(workspaceId), setupType: .workspace, modelType: Workspace.self) { [weak self] result in
            guard let self = self else { return completion(false, "Object memory released.", nil) }
            DispatchQueue.main.async { [unowned self] in
                switch result {
                case .success(let workspaces):
                    
                    guard let longQuestsResponse = workspaces.longFormQuest else {
                        self.isLoading = false
                        completion(false, "Please configure longform.", nil )
                        return
                    }
                    // Validate quest query
                    do {
                        for item in longQuestsResponse.elements {
                                _ = try item.questQuery.toElementFilterExpression()
                            }
                        } catch {
                            print("Invalid quest filter: \(error)")
                            self.isLoading = false
                            completion(false, "Invalid quest query.", workspaces)
                            return
                        }

                    self.longQuests = longQuestsResponse.elements
                    self.saveLongQuestsToDefaults(longQuestJson: longQuestsResponse.elements)
                    QuestsRepository.shared.featurePresets = longQuestsResponse.featurePresets ?? []
                    QuestsRepository.shared.customIcons = longQuestsResponse.customIcons ?? []
                    
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
                    completion(true, "", workspaces)
                case .failure(let error):
                    print("ERROR from workspace details api ----?>>>>>>\(error.localizedDescription)")
                    self.isLoading = false
                    completion(false, "Not able to load the workspace details. Please try again later.", nil )
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
