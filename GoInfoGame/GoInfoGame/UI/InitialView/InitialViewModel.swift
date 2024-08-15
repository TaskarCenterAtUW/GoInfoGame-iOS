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
// InitialViewModel - ViewModel for managing data related to initial view
class InitialViewModel: ObservableObject {
    let locationManagerDelegate = LocationManagerDelegate()
    @Published var workspaces: [Workspace] = [] 
    @Published var longQuests: [LongFormModel] = []
    @Published var isLoading: Bool = false
    
    init() {
        locationManagerDelegate.locationManager.delegate = locationManagerDelegate
        locationManagerDelegate.locationManager.requestWhenInUseAuthorization()
        locationManagerDelegate.locationManager.startUpdatingLocation()
        
        locationManagerDelegate.locationUpdateHandler = { [weak self] location in
            guard let self = self else { return }
            // fetch workspace
            fetchWorkspaceFor(currentLocation: location)
        }
        
    }
    // Method for fetching workspaces based on location
    func fetchWorkspaceFor(currentLocation: CLLocationCoordinate2D) {
        isLoading = true
        let latString = "\(currentLocation.latitude)"
        let longString = "\(currentLocation.longitude)"
        ApiManager.shared.fetchWorkspaces(lat: latString, lon: longString) { result in
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
    
    func fetchLongQuestsFor(workspaceId: String,completion: @escaping (Bool) -> Void) {
        isLoading = true

        ApiManager.shared.fetchLongQuests(workspaceId: workspaceId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let longQuestsResponse):
                    self.longQuests = longQuestsResponse
                    self.isLoading = false
                    completion(true)
                case .failure(let error):
                    self.isLoading = false
                    completion(false)
                }
               
            }
        }
    }
}
