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
                                    }
                                })
                            }  label: {
                                Text(workspace.title)
                                    .font(.system(size: 17))
                                    .frame(maxWidth: .infinity, maxHeight: 40)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(red: 66/255, green: 82/255, blue: 110/255))
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

#Preview {
    InitialView()
    
}


