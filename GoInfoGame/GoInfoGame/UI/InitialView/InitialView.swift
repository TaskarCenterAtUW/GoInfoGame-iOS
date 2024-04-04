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
    
    var body: some View {
        NavigationView {
            // Checking if there are multiple workspaces
            if viewModel.workspaces.count > 1 {
                WorkspacesListView(workspaces: viewModel.workspaces)
            // Checking if there's only one workspace
            } else if viewModel.workspaces.count == 1 {
                if let selectedWorkspace = viewModel.workspaces.first {
                    NavigationLink(destination: MapView(selectedWorkspace: selectedWorkspace).navigationBarBackButtonHidden(true), isActive: $shouldNavigateToMapView) {
                        EmptyView()
                    }.hidden()
                        .onAppear {
                            shouldNavigateToMapView = true
                        }
                } else {
                    EmptyView()
                }
            }else {
                // Displaying progress view if no workspaces are available
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .padding(20)
                    
                    Text("Looking for Workspaces...")
                        .foregroundColor(.gray)
                        .font(.headline)
                        .padding(.bottom, 10)

                }
                .frame(width: 200, height: 150)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white).shadow(radius: 5))
            }
        }
    }
}
// WorkspacesListView - View for displaying a list of workspaces
struct WorkspacesListView: View {
    let workspaces: [Workspace]
    var body: some View {
        List {
            Section(header: Text("Please pick the workspace you want to contribute to").font(.headline)) {
                ForEach(workspaces, id: \.id) { workspace in
                    NavigationLink(destination: MapView(selectedWorkspace: workspace).navigationBarBackButtonHidden(true)) {
                        Text(workspace.name)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}
