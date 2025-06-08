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
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    init(viewModel: WorkspacesViewModel = WorkspacesViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(alignment: .center, spacing: 0) {
                    WorkspaceHeaderView()
                    Group {
                        switch viewModel.state {
                        case .loading(let context):
                            Spacer() // Prevents layout shift when overlay is shown
                        case .loaded(let context):
                            switch context {
                            case .workspaces:
                                if viewModel.workspaces.count == 0 {
                                    NoWorkspacesView()
                                } else {
                                    WorkspaceListView(workspaces: viewModel.workspaces.filter { $0.type == "osw" && $0.externalAppAccess == 1 }, viewModel: viewModel, showErrorAlert: $showErrorAlert, errorMessage: $errorMessage)
                                }
                            }
                        case .error:
                            if viewModel.workspaces.count == 0 {
                                NoWorkspacesView()
                            } else {
                                WorkspaceListView(workspaces: viewModel.workspaces.filter { $0.type == "osw" && $0.externalAppAccess == 1 }, viewModel: viewModel, showErrorAlert: $showErrorAlert, errorMessage: $errorMessage)
                            }
                        case .idle:
                            EmptyView()
                        }
                    }
                    .padding(.top, 30)
                    Spacer()
                }
                .padding(.horizontal)
                
                NavigationCoordinator(route: $viewModel.route)
                
                // Move overlays to the top of the ZStack so they cover everything
                if case .loading(let context) = viewModel.state {
                    LoadingOverlayView(activityText: context.loadingMessage)
                        .edgesIgnoringSafeArea(.all)
                }
                if viewModel.isLoadingQuests {
                    LoadingOverlayView(activityText: "Loading Quests...")
                        .edgesIgnoringSafeArea(.all)
                }
                
                if let errorMessage = viewModel.popupError {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)

                    ErrorAlertView(
                        message: errorMessage,
                        onDismiss: {
                            viewModel.popupError = nil
                        }
                    )
                }
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
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct WorkspaceListView: View {
    let workspaces: [Workspace]
    @ObservedObject var viewModel: WorkspacesViewModel
    @Binding var showErrorAlert: Bool
    @Binding var errorMessage: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(workspaces, id: \.id) { workspace in
                    Button {
                        viewModel.checkAndDeleteWorkspaceDB(workspaceId: "\(workspace.id)")
                        viewModel.fetchLongQuestsFor(workspace: workspace)
                        AuthSessionManager.shared.setWorkspaceId("\(workspace.id)")
                    } label: {
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
            .padding()
        }
    }
}

struct NoWorkspacesView: View {
    var body: some View {
        Text("No workspaces available for you to work on.")
            .font(.custom("Lato-Bold", size: 20))
            .foregroundColor((Color(red: 135/255, green: 62/255, blue: 242/255)))
            .multilineTextAlignment(.center)
    }
}

struct WorkspaceHeaderView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                NavigationLink(destination: UserProfileView()) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 27, height: 27)
                        .foregroundStyle(Color(red: 135/255, green: 62/255, blue: 242/255))
                }
                Spacer()
            }
            .padding(.top, 10)
            .padding(.horizontal, 18)
            HStack {
                Spacer()
                VStack(spacing: 30) {
                    Image("osmlogo")
                        .resizable()
                        .frame(width: 100, height: 100)
                    Text("GoInfoGame")
                        .font(.system(size: 30, design: .rounded))
                }
                Spacer()
            }
            .padding(.top, 20)
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
    vm.state = .loading(.workspaces)
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
    vm.state = .loaded(.workspaces)
    vm.workspaces = []
    vm.isPreview = true
    return WorkspaceSelectionView(viewModel: vm)
}
#Preview("LOADED - WORKSPACE") {
    let vm = WorkspacesViewModel()
    vm.state = .loaded(.workspaces)
    vm.workspaces = [Workspace(id: 1, title: "Sample Workspace", type: "osw", externalAppAccess: 1)]
    vm.isPreview = true
    return WorkspaceSelectionView(viewModel: vm)
}

#Preview("Selected a Corupted Workspace") {
    let vm = WorkspacesViewModel()
    vm.state = .loaded(.workspaces)
    vm.workspaces = [Workspace(id: 1, title: "Sample Workspace", type: "osw", externalAppAccess: 1)]
    vm.popupError = "Invalid quest query"
    vm.isPreview = true
    return WorkspaceSelectionView(viewModel: vm)
}
