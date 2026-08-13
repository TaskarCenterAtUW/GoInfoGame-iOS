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
    @State private var isSearchActive = false
    @FocusState private var isSearchFieldFocused: Bool
    @AppStorage("loggedIn") private var loggedIn: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    HStack {
                        if !isSearchActive {
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
                                    .frame(minWidth: 44, minHeight: 44) // Explicitly meet accessibility tap target standards
                                    .contentShape(Rectangle())
                                    .accessibilityLabel(L10n.Localizable.profile)
                            }
                        }

                        if isSearchActive {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                TextField("Search workspaces by title", text: $viewModel.searchText)
                                    .font(.custom("Lato-Regular", size: 16, relativeTo: .body))
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                    .focused($isSearchFieldFocused)
                                    .accessibilityLabel("Search workspaces by title")
                                if !viewModel.searchText.isEmpty {
                                    Button {
                                        viewModel.searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .frame(minWidth: 44, minHeight: 44)
                                            .contentShape(Rectangle())
                                    }
                                    .accessibilityLabel("Clear search text")
                                }
                            }
                            .padding(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        } else {
                            Spacer()
                        }

                        Button {
                            withAnimation {
                                isSearchActive.toggle()
                                if isSearchActive {
                                    isSearchFieldFocused = true
                                } else {
                                    viewModel.searchText = ""
                                }
                            }
                        } label: {
                            Image(systemName: isSearchActive ? "xmark.circle.fill" : "magnifyingglass")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel(isSearchActive ? "Close search" : "Search workspaces")
                    }

                    VStack(spacing: 20) {
                        Asset.workspacesLogo.swiftUIImage
                            .resizable()
                            .frame(width: 100, height: 100)
                            .accessibilityHidden(true)
                        Text(L10n.Localizable.appName)
                            .font(.system(.title, design: .rounded))
                            .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .minimumScaleFactor(0.5) // "ScoutRoute" has no space to wrap on; shrink rather than truncate if it's ever too wide
                    }
                    .padding()

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
    @ObservedObject var viewModel: InitialViewModel
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
                viewModel.fetchLongQuestsFor(workspaceId: "\(selectedWorkspace.id)") { success, errorMessage, workspace  in
                    if success {
                        self.selectedWorkspace = workspace
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
                ScrollView {
                    VStack {
                        Text("Loading workspaces available for you... Please make sure you have location service enabled.")
                            .font(.custom("Lato-Bold", size: 20, relativeTo: .body))
                            .foregroundColor((Asset.Colors.huskyPurple.swiftUIColor))
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                ScrollView {
                    VStack {
                        Text(viewModel.errorMessage ?? "Something went wrong. Please try again later.")
                            .font(.custom("Lato-Bold", size: 20, relativeTo: .body))
                            .foregroundColor((Asset.Colors.huskyPurple.swiftUIColor))
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
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
                                        .font(.custom("Lato-Bold", size: 20, relativeTo: .body))
                                }
                            }
                            .foregroundStyle(Asset.Colors.accentPink.swiftUIColor)
                        }
                        .padding(.top, 20)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        } else if viewModel.workspaces?.count == 0 {
            ScrollView {
                VStack {
                    Text("No workspaces available for you to work on.")
                        .font(.custom("Lato-Bold", size: 20, relativeTo: .body))
                        .foregroundColor((Asset.Colors.huskyPurple.swiftUIColor))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }

        } else {
            ScrollView {
                VStack(spacing: 10) {
                    Text("Pick the workspace you want to contribute to")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                        .multilineTextAlignment(.center)

                    if !viewModel.projectGroupIds.isEmpty {
                        Menu {
                            Button {
                                viewModel.selectedProjectGroupId = nil
                            } label: {
                                if viewModel.selectedProjectGroupId == nil {
                                    Label("All Project Groups", systemImage: "checkmark")
                                } else {
                                    Text("All Project Groups")
                                }
                            }
                            ForEach(viewModel.projectGroupIds, id: \.self) { groupId in
                                Button {
                                    viewModel.selectedProjectGroupId = groupId
                                } label: {
                                    if viewModel.selectedProjectGroupId == groupId {
                                        Label(viewModel.projectGroupDisplayName(for: groupId), systemImage: "checkmark")
                                    } else {
                                        Text(viewModel.projectGroupDisplayName(for: groupId))
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text("Project Group: \(viewModel.projectGroupDisplayName(for: viewModel.selectedProjectGroupId))")
                                    .font(.custom("Lato-Regular", size: 15, relativeTo: .body))
                                    .lineLimit(nil)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                            }
                            .padding(10)
                            .frame(minHeight: 44)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        .accessibilityLabel("Filter by project group. Currently: \(viewModel.projectGroupDisplayName(for: viewModel.selectedProjectGroupId))")
                    }

                    if viewModel.filteredWorkspaces.isEmpty {
                        VStack(spacing: 12) {
                            Text("No workspaces match your search or filter.")
                                .font(.custom("Lato-Bold", size: 17, relativeTo: .body))
                                .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                                .multilineTextAlignment(.center)
                            Button("Clear filters") {
                                viewModel.clearFilters()
                            }
                            .font(.custom("Lato-Bold", size: 15, relativeTo: .body))
                            .foregroundColor(Asset.Colors.accentPink.swiftUIColor)
                            .frame(minHeight: 44)
                        }
                        .padding(.top, 20)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(viewModel.filteredWorkspaces, id: \.id) { workspace in
                                Button {
                                    viewModel.checkAndDeleteWorkspaceDB(workspaceId: "\(workspace.id)")
                                    viewModel.fetchLongQuestsFor(workspaceId: "\(workspace.id)", completion: { success, errorMessage, ws in
                                        if success {
                                            shouldNavigateToMapView = true
                                            selectedWorkspace = ws

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
                                    VStack(spacing: 4) {
                                        Text(workspace.title)
                                            .font(.custom("Lato-Bold", size: 17, relativeTo: .body))
                                            .foregroundColor(Color.white)
                                        if let createdDateDisplay = workspace.createdDateDisplay {
                                            Text("Created \(createdDateDisplay)")
                                                .font(.custom("Lato-Regular", size: 12, relativeTo: .caption))
                                                .foregroundColor(Color.white.opacity(0.8))
                                        }
                                    }
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity, minHeight: 50)
                                    .background(Asset.Colors.huskyPurple.swiftUIColor)
                                    .cornerRadius(9)
                                }
                            }
                        }
                        .padding()
                    }
                }
                .padding([.leading, .trailing])
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertMessage), dismissButton: .cancel())
            }
        }
    }
}

struct LocationDisabledView: View {
    var body: some View {
        VStack {
            Text(L10n.Localizable.appName)
                .font(.custom("Lato-Bold", size: 30, relativeTo: .title))
                .foregroundColor((Asset.Colors.huskyPurple.swiftUIColor))
                .padding([.bottom], 50)
            
            Text("Location Services Disabled")
                .font(.custom("Lato-Bold", size: 25, relativeTo: .title2))
                .padding()
            Text("Please enable location services on your device settings to use this app.")
                .font(.custom("Lato-Bold", size: 19, relativeTo: .body))
                .multilineTextAlignment(.center)
                .padding()
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Open Settings")
                    .font(.custom("Lato-Bold", size: 20, relativeTo: .body))
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
