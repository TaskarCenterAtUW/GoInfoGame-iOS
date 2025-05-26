//
//  NavigationHandler.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 26/05/25.
//

import SwiftUI

enum NavigationRoute {
    case workspace
    case profile
    case map(workspace: Workspace)
}

struct NavigationCoordinator: View {
    @Binding var route: NavigationRoute?

    var body: some View {
        NavigationLink(
            destination: destinationView(),
            isActive: Binding(
                get: { route != nil },
                set: { if !$0 { route = nil } }
            )
        ) {
            EmptyView()
        }
    }

    @ViewBuilder
    private func destinationView() -> some View {
        switch route {
        case .workspace:
            WorkspaceView()
        case .profile:
            UserProfileView()
        case .map(let workspace):
            MapView(selectedWorkspace: workspace)
        case .none:
            EmptyView()
        }
    }
}
