//
//  WorkspaceView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 03/04/24.
//

import SwiftUI
// WorkspaceView - Main view for displaying available workspaces and navigating to MapView
struct WorkspaceSelectionView: View {
    @StateObject private var viewModel: WorkspacesViewModel
    @Environment(\.scenePhase) private var scenePhase
    
    init(viewModel: WorkspacesViewModel = WorkspacesViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(alignment: .center, spacing: 0) {
                    HStack {
                        NavigationLink(destination: UserProfileView()) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 27, height: 27)
                                .padding(.leading, 18)
                                .foregroundStyle(Color(red: 135/255, green: 62/255, blue: 242/255))
                        }
                        Spacer()
                    }
                    .padding(.top, 10)
                    // Logo and Title pinned to top
                    VStack(spacing: 30) {
                        Image("osmlogo")
                            .resizable()
                            .frame(width: 100, height: 100)
                        Text("GoInfoGame")
                            .font(.system(size: 30, design: .rounded))
                    }
                    .padding(.top, 20)
                    // State-based UI below logo/title
                    Group {
                        if case let .error(errorMessage) = viewModel.state {
                            Text("TO DO: DISPLAY ERROR")
                                .font(.custom("Lato-Bold", size: 20))
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, 8)
                        }
                        switch viewModel.state {
                        case .loading:
                            ActivityView(activityText: "Loading workspaces...")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                              
                        case .loaded:
                           
                            if viewModel.workspaces.count == 0 {
                                Text("No workspaces available for you to work on.")
                                    .font(.custom("Lato-Bold", size: 20))
                                    .foregroundColor((Color(red: 135/255, green: 62/255, blue: 242/255)))
                                    .multilineTextAlignment(.center)
                            } else {
                                ScrollView {
                                    VStack(spacing: 20) {
                                        ForEach(viewModel.workspaces.filter({$0.type == "osw" && $0.externalAppAccess == 1}), id: \.id) { workspace in
                                            Button {
                                                viewModel.checkAndDeleteWorkspaceDB(workspaceId: "\(workspace.id)")
                                                viewModel.fetchLongQuestsFor(workspaceId: "\(workspace.id)", completion: { success, errorMessage in
                                                    
                                                })
                                            } label: {
                                                Text(workspace.title)
                                                    .font(.system(size: 17))
                                                    .frame(maxWidth: .infinity, maxHeight: 40)
                                                    .padding()
                                                    .background(Color(red: 242/255, green: 242/255, blue: 242/255))
                                                    .cornerRadius(10)
                                            }
                                        }
                                    }
                                }
                                
                                
                                
                                
                                
                                
                                
                                
//                                ScrollView {
//                                            VStack(spacing: 20) {
//                                                ForEach(viewModel.workspaces.filter({$0.type == "osw" && $0.externalAppAccess == 1}), id: \.id) { workspace in
//                                                    Button {
//                                                        viewModel.checkAndDeleteWorkspaceDB(workspaceId: "\(workspace.id)")
//                                                        viewModel.fetchLongQuestsFor(workspaceId: "\(workspace.id)", completion: { success, errorMessage in
//                                                            if success {
//                                                                self.shouldNavigateToMapView = true
//                                                                self.selectedWorkspace = workspace
//                                                                
//                                                                let workspaceId = "\(workspace.id)"
//                                                                AuthSessionManager.shared.setWorkspaceId(workspaceId)
//                                                            } else {
//                                                                DispatchQueue.main.async {
//                                                                    alertMessage = errorMessage ?? "Something went wrong."
//                                                                    
//                                                                    showAlert = true
//                                                                
//                                                                    self.shouldNavigateToMapView = false
//                                                                }
//                                                            }
//                                                        })
//                                                    }  label: {
//                                                        Text(workspace.title)
//                                                            .font(.system(size: 17))
//                                                            .frame(maxWidth: .infinity, maxHeight: 40)
//                                                    }
//                                                    .font(.custom("Lato-Bold", size: 25))
//                                                    .foregroundColor(Color.white)
//                                                    .padding()
//                                                    .background(Color(red: 135/255, green: 62/255, blue: 242/255))
//                                                    .buttonBorderShape(.roundedRectangle(radius: 10))
//                                                }
//                                            }
//                                        }
//                                .onAppear {
//                                    
//                                }
//                                .padding()
                            }
                                    
                        case .error(_):
                            EmptyView()
                        case .idle:
                            EmptyView()
                        }
                    }
                    .padding(.top, 30)
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            viewModel.enableLocationTracking()
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                viewModel.enableLocationTracking()
            case .background:
                viewModel.disableLocationTracking()
            default:
                break
            }
        }
        .toolbar(.hidden)
    }
}

struct WorkspaceView: View {
    @StateObject private var viewModel = WorkspacesViewModel()
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var shouldNavigateToMapView = false
            
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
                    switch viewModel.state {
                    case .loading:
                        ActivityView(activityText: "Loading workspaces...")
                    case .loaded:
                        if viewModel.workspaces.count == 0 {
                            Text("No workspaces available for you to work on.")
                                .font(.custom("Lato-Bold", size: 20))
                                .foregroundColor((Color(red: 135/255, green: 62/255, blue: 242/255)))
                                .multilineTextAlignment(.center)
                        } else if viewModel.workspaces.count == 1 {
                            if let selectedWorkspace = viewModel.workspaces.first {
                                WorkspacesListView(workspaces: viewModel.workspaces, viewModel: viewModel)
                                    .navigationDestination(isPresented: $shouldNavigateToMapView) {
                                        MapView(selectedWorkspace: selectedWorkspace)
                                            .navigationBarBackButtonHidden(true)
                                    }
                            }
                        } else {
                            WorkspacesListView(workspaces: viewModel.workspaces, viewModel: viewModel)
                        }
                    case .error(let error):
                        Text("Error: \(error)")
                    case .idle:
                        EmptyView()
                    }
                   }
                .padding()

            }
        }
        .onAppear {
            viewModel.enableLocationTracking()
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                viewModel.enableLocationTracking()
            case .background:
                viewModel.disableLocationTracking()
            default:
                break
            }
        }
        .toolbar(.hidden)
       }
}

// WorkspacesListView - View for displaying a list of workspaces
struct WorkspacesListView: View {
    let workspaces: [Workspace]
    var viewModel: WorkspacesViewModel
    @State private var shouldNavigateToMapView = false
    @State private var selectedWorkspace: Workspace?
    
    @State private var showAlert = false
    
    @State private var alertMessage = ""

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
                    viewModel.fetchLongQuestsFor(workspaceId: "\(selectedWorkspace.id)") { success, errorMessage  in
                        if success {
                            let workspaceId = "\(selectedWorkspace.id)"
                            AuthSessionManager.shared.setWorkspaceId(workspaceId)
                            DispatchQueue.main.async {
                                self.shouldNavigateToMapView = true
                            }
                        } else {
                            DispatchQueue.main.async {
                                alertMessage = errorMessage ?? "Something went wrong. Please pick another workspace."
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

                Spacer()
            }
           
        } else {
            VStack {
                Text("Pick the workspace you want to contribute to")

                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(.gray)
                
//                ScrollView {
//                            VStack(spacing: 20) {
//                                ForEach(workspaces.filter({$0.type == "osw" && $0.externalAppAccess == 1}), id: \.id) { workspace in
//                                    Button {
//                                        viewModel.checkAndDeleteWorkspaceDB(workspaceId: "\(workspace.id)")
//                                        viewModel.fetchLongQuestsFor(workspaceId: "\(workspace.id)", completion: { success, errorMessage in
//                                            if success {
//                                                self.shouldNavigateToMapView = true
//                                                self.selectedWorkspace = workspace
//                                                
//                                                let workspaceId = "\(workspace.id)"
//                                                AuthSessionManager.shared.setWorkspaceId(workspaceId)
//                                            } else {
//                                                DispatchQueue.main.async {
//                                                    alertMessage = errorMessage ?? "Something went wrong."
//                                                    
//                                                    showAlert = true
//                                                
//                                                    self.shouldNavigateToMapView = false
//                                                }
//                                            }
//                                        })
//                                    }  label: {
//                                        Text(workspace.title)
//                                            .font(.system(size: 17))
//                                            .frame(maxWidth: .infinity, maxHeight: 40)
//                                    }
//                                    .font(.custom("Lato-Bold", size: 25))
//                                    .foregroundColor(Color.white)
//                                    .padding()
//                                    .background(Color(red: 135/255, green: 62/255, blue: 242/255))
//                                    .buttonBorderShape(.roundedRectangle(radius: 10))
//                                }
//                            }
//                        }
//                .onAppear {
//                    
//                }
//                .padding()
            }
            .alert(alertMessage, isPresented: $showAlert) {
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


#Preview("Loading") {
    let vm = WorkspacesViewModel()
    vm.state = .loading
    vm.isPreview = true
    return WorkspaceSelectionView(viewModel: vm)
}

#Preview("Error") {
    let vm = WorkspacesViewModel()
    vm.state = .error("Something went wrong")
    vm.isPreview = true
    return WorkspaceSelectionView(viewModel: vm)
}

#Preview("LOADED - ZERO WORKSPACE") {
    let vm = WorkspacesViewModel()
    vm.state = .loaded
    vm.workspaces = []
    vm.isPreview = true
    return WorkspaceSelectionView(viewModel: vm)
}

    
