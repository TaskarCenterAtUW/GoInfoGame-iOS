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
        NavigationView {
            
            if locManagerDelegate.isLocationServicesOff || locManagerDelegate.isLocationDenied {
                LocationDisabledView()
            } else {
                // Checking if there are multiple workspaces
                if viewModel.workspaces.count > 1 {
                    WorkspacesListView(workspaces: viewModel.workspaces, viewModel: viewModel)
                    // Checking if there's only one workspace
                } else if viewModel.workspaces.count == 1 {
                    if let selectedWorkspace = viewModel.workspaces.first {
                        NavigationLink(destination: MapView(selectedWorkspace: selectedWorkspace).navigationBarBackButtonHidden(true), isActive: $shouldNavigateToMapView) {
                            EmptyView()
                        }.hidden()
                            .onAppear {
                                shouldNavigateToMapView = true
                                //  selectedWorkspace.saveQuestsToUserDefaults()
                            }
                    } else {
                        EmptyView()
                    }
                }else {
                    // Displaying progress view if no workspaces are available
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
                            .simultaneousGesture(TapGesture().onEnded {
                              //  workspace.saveQuestsToUserDefaults()
                            })
                        }
                    }
                }
                .padding()
            }
            .padding()
            
            if shouldNavigateToMapView, let selectedWorkspace = selectedWorkspace {
         
                           NavigationLink(
                               destination: MapView(selectedWorkspace: selectedWorkspace)

                                   .navigationBarBackButtonHidden(true),
                               isActive: $shouldNavigateToMapView,
                               label: {
                                   EmptyView()
                               }
                           )
                       }
        }
    }
}

struct LocationDisabledView: View {
    var body: some View {
        VStack {
            Text("Location Services Disabled")
                .font(.title)
                .padding()
            Text("Please enable location services on your device settings to use this app.")
                .multilineTextAlignment(.center)
                .padding()
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Open Settings")
                    .foregroundColor(.blue)
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    InitialView()
    
}


