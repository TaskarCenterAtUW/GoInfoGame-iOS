//
//  InitialView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 03/04/24.
//

import SwiftUI

struct InitialView: View {
    @StateObject private var viewModel = InitialViewModel()
    @State private var shouldNavigateToMapView = false
    
    var body: some View {
        NavigationView {
            if viewModel.workspaces.count > 1 {
                WorkspacesListView(workspaces: viewModel.workspaces)
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
            } else {
                LoadingView()
            }
        }
    }
}
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
