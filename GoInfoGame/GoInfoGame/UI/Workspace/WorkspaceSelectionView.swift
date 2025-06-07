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
                    WorkspaceHeaderView()
                    Group {
                        if case let .error(errorMessage) = viewModel.state {
                            WorkspaceErrorView(errorMessage: errorMessage)
                        }
                        switch viewModel.state {
                        case .loading(let context):
                            ActivityView(activityText: context.loadingMessage)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case .loaded(let context):
                            switch context {
                            case .workspaces:
                                if viewModel.workspaces.count == 0 {
                                    NoWorkspacesView()
                                } else {
                                    WorkspaceListView(workspaces: viewModel.workspaces.filter { $0.type == "osw" && $0.externalAppAccess == 1 }, viewModel: viewModel)
                                }
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
                
                NavigationCoordinator(route: $viewModel.route)
                
                if viewModel.isLoadingQuests {
                    LoadingOverlayView()
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
    }
}

struct WorkspaceListView: View {
    let workspaces: [Workspace]
    @ObservedObject var viewModel: WorkspacesViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(workspaces, id: \.id) { workspace in
                    Button {
                        viewModel.checkAndDeleteWorkspaceDB(workspaceId: "\(workspace.id)")
                        viewModel.isLoadingQuests = true
                        viewModel.fetchLongQuestsFor(workspace: workspace, completion: { success, errorMessage in
                            print("Fetched long quests for workspace \(workspace.id): success = \(success), error = \(String(describing: errorMessage))")
                            if success {
                                let workspaceId = "\(workspace.id)"
                                AuthSessionManager.shared.setWorkspaceId(workspaceId)
                                // TODO: Navigate to next screen here
                            } else {
                                print("Error fetching long quests: \(errorMessage ?? "Unknown error")")
                            }
                        })
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

struct WorkspaceErrorView: View {
    let errorMessage: String
    var body: some View {
        Text(errorMessage)
            .font(.custom("Lato-Bold", size: 20))
            .foregroundColor(.red)
            .font(.caption)
            .padding(.top, 8)
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

struct LoadingOverlayView: View {
    var body: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        VStack {
            Spacer()
            ActivityView(activityText: "Loading quests...")
                .frame(maxWidth: .infinity)
            Spacer()
        }
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
