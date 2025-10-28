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
    @State private var selectedWorkspace: Workspace? = nil
    @AppStorage("loggedIn") private var loggedIn: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    HStack {
                        NavigationLink(destination: UserProfileView()) {
                            Image(systemName: "person.fill")
                                .resizable()
                                .padding(8)
                                .foregroundStyle(Color.white)
                                .background {
                                    LinearGradient(gradient: Gradient(colors: [Asset.Colors._8F57DEProfileIcon.swiftUIColor, Asset.Colors._2D0369ProfileIcon.swiftUIColor,]), startPoint: .top, endPoint: .bottom)
                                }
                                .frame(width: 34, height: 34)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 30) {
                        Asset.workspacesLogo.swiftUIImage
                            .resizable()
                            .frame(width: 100, height: 100)
                        Text(L10n.Localizable.appName)
                            .font(.system(size: 30, design: .rounded))
                            .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                    }
                    .padding()
                    
                    Spacer()
                    
                    WorkspacesListView(viewModel: viewModel, shouldNavigateToMapView: $shouldNavigateToMapView, selectedWorkspace: $selectedWorkspace, isLoading: $viewModel.isLoading)
                }
                .padding()
                
                if viewModel.isLoading {
                    ActivityView(activityText: "Fetching workspaces")
                }
            }
            .navigationDestination(isPresented: $shouldNavigateToMapView) {
                if let workspace = selectedWorkspace {
                    MapView(selectedWorkspace: workspace, viewModel: MapViewModel(workspace: workspace))
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
        .toolbar(.hidden)
    }
}

// WorkspacesListView - View for displaying a list of workspaces
struct WorkspacesListView: View {
    var viewModel: InitialViewModel
    @Binding var shouldNavigateToMapView: Bool
    @Binding var selectedWorkspace: Workspace?
    
    @Binding var isLoading: Bool
    
    @State private var showAlert = false
    
    @State private var alertMessage = ""
    @State private var autoRedirectToMapViewError: String?
    
    var body: some View {
        
        if viewModel.workspaces?.count == 1,
           let selectedWorkspace = viewModel.workspaces?.first,
           autoRedirectToMapViewError == nil {
            VStack {
            }
            .onAppear {
                viewModel.fetchLongQuestsFor(workspaceId: "\(selectedWorkspace.id)") { success, errorMessage  in
                    if success {
                        self.selectedWorkspace = selectedWorkspace
                        let workspaceId = "\(selectedWorkspace.id)"
                        _ = KeychainManager.save(key: "workspaceID", data: workspaceId)
                        DispatchQueue.main.async {
                            shouldNavigateToMapView = true
                        }
                    } else {
                        autoRedirectToMapViewError = errorMessage ?? "Something went wrong. Please pick another workspace."
                    }
                }
            }
        } else if viewModel.workspaces == nil {
            if viewModel.errorMessage == nil {
                VStack {
                    Text("Loading workspaces available for you... Please make sure you have location service enabled.")
                        .font(.custom("Lato-Bold", size: 20))
                        .foregroundColor((Asset.Colors.huskyPurple.swiftUIColor))
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            } else {
                VStack {
                    Text(viewModel.errorMessage ?? "Something went wrong. Please try again later.")
                        .font(.custom("Lato-Bold", size: 20))
                        .foregroundColor((Asset.Colors.huskyPurple.swiftUIColor))
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                    Spacer()
                    Button {
                        if let location = viewModel.currentLocation {
                            viewModel.fetchWorkspacesList(location: location)
                        }
                    } label: {
                        Group {
                            VStack {
                                Image(systemName: "arrow.clockwise")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                Text("Try again")
                                    .font(.custom("Lato-Bold", size: 20))
                            }
                        }
                        .foregroundStyle(Asset.Colors.accentPink.swiftUIColor)
                        
                        
                    }
                    Spacer()
                }
            }
        } else if viewModel.workspaces?.count == 0 {
            VStack {
                Text("No workspaces available for you to work on.")
                    .font(.custom("Lato-Bold", size: 20))
                    .foregroundColor((Asset.Colors.huskyPurple.swiftUIColor))
                    .multilineTextAlignment(.center)
                Spacer()
            }
            
        } else {
            VStack {
                Text("Pick the workspace you want to contribute to")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(.gray)
                
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(viewModel.workspaces?.filter({$0.type == "osw" && $0.externalAppAccess == 1}) ?? [], id: \.id) { workspace in
                            Button {
                                viewModel.checkAndDeleteWorkspaceDB(workspaceId: "\(workspace.id)")
                                viewModel.fetchLongQuestsFor(workspaceId: "\(workspace.id)", completion: { success, errorMessage in
                                    if success {
                                        shouldNavigateToMapView = true
                                        selectedWorkspace = workspace
                                        
                                        let workspaceId = "\(workspace.id)"
                                        _ = KeychainManager.save(key: "workspaceID", data: workspaceId)
                                    } else {
                                        DispatchQueue.main.async {
                                            alertMessage = errorMessage ?? "Something went wrong."
                                            
                                            showAlert = true
                                            
                                            shouldNavigateToMapView = false
                                        }
                                    }
                                })
                            }  label: {
                                Text(workspace.title)
                                    .font(.custom("Lato-Bold", size: 17))
                                    .frame(maxWidth: .infinity, minHeight: 50)
                                    .foregroundColor(Color.white)
                                    .background(Asset.Colors.huskyPurple.swiftUIColor)
                                    .cornerRadius(9)
                            }
                        }
                    }
                }
                .padding()
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }
}

struct LocationDisabledView: View {
    var body: some View {
        VStack {
            Text(L10n.Localizable.appName)
                .font(.custom("Lato-Bold", size: 30))
                .foregroundColor((Asset.Colors.huskyPurple.swiftUIColor))
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
    InitialView()
}





