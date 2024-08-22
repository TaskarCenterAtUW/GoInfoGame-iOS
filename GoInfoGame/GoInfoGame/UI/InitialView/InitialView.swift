//
//  InitialView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 03/04/24.
//

import SwiftUI
// InitialView - Main view for displaying available workspaces and navigating to MapVie
struct InitialView: View {
    @StateObject private var viewModel = InitialViewModel()
    @State private var shouldNavigateToMapView = false
    @StateObject private var locManagerDelegate = LocationManagerDelegate()

    var body: some View {
        NavigationStack {
            if locManagerDelegate.isLocationServicesOff || locManagerDelegate.isLocationDenied {
                LocationDisabledView()
            } else {
                if viewModel.workspaces.count > 1 {
                    WorkspacesListView(workspaces: viewModel.workspaces, viewModel: viewModel)
                } else if viewModel.workspaces.count == 1 {
                    if let selectedWorkspace = viewModel.workspaces.first {
                        VStack {
                            if !shouldNavigateToMapView {
                                ActivityView(activityText: "Fetching workspace data...")
                            }
                        }
                        .onAppear {
                            viewModel.fetchLongQuestsFor(workspaceId: "\(selectedWorkspace.id)") { success in
                                if success {
                                    let workspaceId = "\(selectedWorkspace.id)"
                                    _ = KeychainManager.save(key: "workspaceID", data: workspaceId)
                                    DispatchQueue.main.async {
                                        self.shouldNavigateToMapView = true
                                    }
                                }
                            }
                        }
                        .navigationDestination(isPresented: $shouldNavigateToMapView) {
                            MapView(selectedWorkspace: selectedWorkspace)
                                .navigationBarBackButtonHidden(true)
                        }
                    }
                } else {
                    ActivityView(activityText: "Looking for workspaces...")
                }
            }
        }
        .onAppear {
            viewModel.locationManagerDelegate.requestLocationAuthorization()
        }
        .navigationBarBackButtonHidden(true)
    }
}

// WorkspacesListView - View for displaying a list of workspaces
struct WorkspacesListView: View {
    let workspaces: [Workspace]
    var viewModel: InitialViewModel
    @State private var shouldNavigateToMapView = false
    @State private var selectedWorkspace: Workspace?

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                VStack(spacing: 30) {
                    Image("osmlogo")
                        .resizable()
                        .frame(width: 100, height: 100)
                    Text("GoInfoGame")
                        .font(.system(size: 30, design: .rounded))
                    Text("Pick the workspace you want to contribute to")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundStyle(.gray)
                }
                .padding()
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(workspaces, id: \.id) { workspace in
                            Button {
                                viewModel.fetchLongQuestsFor(workspaceId: "\(workspace.id)", completion: { success in
                                    if success {
                                        self.shouldNavigateToMapView = true
                                        self.selectedWorkspace = workspace
                                        
                                        let workspaceId = "\(workspace.id)"
                                        _ = KeychainManager.save(key: "workspaceID", data: workspaceId)
                                    }
                                })
                            }  label: {
                                Text(workspace.title)
                                    .font(.system(size: 17))
                                    .frame(maxWidth: .infinity, maxHeight: 40)
                            }
                            .font(.custom("Lato-Bold", size: 25))
                            .foregroundColor(Color.white)
                            .padding()
                            .background(Color(red: 135/255, green: 62/255, blue: 242/255))
                            .buttonBorderShape(.roundedRectangle(radius: 10))
                        }
                    }
                }
                .padding()
            }
            .padding()

            if shouldNavigateToMapView, let selectedWorkspace = selectedWorkspace {
                NavigationLink(value: selectedWorkspace) {
                    EmptyView()
                }
                .navigationDestination(isPresented: $shouldNavigateToMapView) {
                    MapView(selectedWorkspace: selectedWorkspace)
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
    }
}

struct LocationDisabledView: View {
    var body: some View {
        VStack {
            Text("GoInfoGame")
                .font(.custom("Lato-Bold", size: 30))
                .foregroundColor((Color(red: 135/255, green: 62/255, blue: 242/255)))
                .padding([.bottom], 50)

            Text("Location Services Disabled")
                .font(.custom("Lato-Bold", size: 25))
                .padding()
            Text("Please enable location services on your device settings to use this app.")
                .font(.custom("Lato-Bold", size: 19))
                .multilineTextAlignment(.center)
                .padding()
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Open Settings")
                    .font(.custom("Lato-Bold", size: 20))
                    .foregroundColor(.blue)
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    LocationDisabledView()
    
}


