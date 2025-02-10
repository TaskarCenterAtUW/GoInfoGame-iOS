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
    
    @State private var isLoading: Bool = false
    
    @AppStorage("loggedIn") private var loggedIn: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                       HStack {
                           NavigationLink(destination: UserProfileView()) {
                               Image(systemName: "person.crop.circle.fill")
                                   .resizable()
                                   .frame(width: 27, height: 27)
                                   .padding([.leading], 18)
                                   .foregroundStyle(Color(red: 135/255, green: 62/255, blue: 242/255))
                                
                           }
                           Spacer()
                       }
                       .frame(maxWidth: .infinity, alignment: .leading)
                       
                       Spacer()
                       
                       VStack(spacing: 30) {
                           Image("osmlogo")
                               .resizable()
                               .frame(width: 100, height: 100)
                           Text("GoInfoGame")
                               .font(.system(size: 30, design: .rounded))
                       }
                       .padding()
                  
                       Spacer()
                       
      if viewModel.workspaces.count > 1 {
          WorkspacesListView(workspaces: viewModel.workspaces, viewModel: viewModel, isLoading: $isLoading)
                       }
                   }
                .padding()
                
                if isLoading {
                    ActivityView(activityText: "Fetching workspaces")
                       
                }
            }
        }
        .onAppear {
            isLoading = true
        }
        .toolbar(.hidden)
       }
}

// WorkspacesListView - View for displaying a list of workspaces
struct WorkspacesListView: View {
    let workspaces: [Workspace]
    var viewModel: InitialViewModel
    @State private var shouldNavigateToMapView = false
    @State private var selectedWorkspace: Workspace?
    
    @Binding var isLoading: Bool
    
    @State private var showAlert = false
    
    var body: some View {
        
        if viewModel.workspaces.count == 1 {
            if let selectedWorkspace = viewModel.workspaces.first {
                VStack {
                    if !shouldNavigateToMapView {
                        ActivityView(activityText: "Fetching workspace data...")
                        Spacer()
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
                        } else {
                            DispatchQueue.main.async {
                                showAlert = true
                                self.shouldNavigateToMapView = false
                            }
                        }
                    }
                }
                .navigationDestination(isPresented: $shouldNavigateToMapView) {
                    MapView(selectedWorkspace: selectedWorkspace)
                        .navigationBarBackButtonHidden(true)
                }
            }
        } else if viewModel.workspaces.count == 0 {
            VStack {
                Text("No workspaces available for you to work on.")
                    .font(.custom("Lato-Bold", size: 20))
                    .foregroundColor((Color(red: 135/255, green: 62/255, blue: 242/255)))
                    .multilineTextAlignment(.center)
                    .onAppear {
                        isLoading = false
                    }
                Spacer()
            }
           
        } else {
            VStack {
                Text("Pick the workspace you want to contribute to")
                    .onAppear {
                        isLoading = false
                    }
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(.gray)
                
                ScrollView {
                            VStack(spacing: 20) {
                                ForEach(workspaces.filter({$0.type == "osw" && $0.externalAppAccess == 1}), id: \.id) { workspace in
                                    Button {
                                        viewModel.fetchLongQuestsFor(workspaceId: "\(workspace.id)", completion: { success in
                                            if success {
                                                self.shouldNavigateToMapView = true
                                                self.selectedWorkspace = workspace
                                                
                                                let workspaceId = "\(workspace.id)"
                                                _ = KeychainManager.save(key: "workspaceID", data: workspaceId)
                                            } else {
                                                DispatchQueue.main.async {
                                                    showAlert = true
                                                    self.shouldNavigateToMapView = false
                                                }
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
                .onAppear {
                    
                }
                .padding()
            }
            .alert("Workspace or quest not configured", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            }
        }

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
    InitialView()
    
}





