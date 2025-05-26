//
//  GoInfoGameApp.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 27/05/25.
//

import SwiftUI

@main
struct GoInfoGameApp: App {
    @AppStorage("loggedIn") private var loggedIn: Bool = false
    @Environment(\.scenePhase) private var scenePhase
    
    private let locationManagerDelegate = LocationManagerDelegate()

    init() {
        AuthSessionManager.shared.validateAccessToken()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if loggedIn {
                    WorkspaceView()
                } else {
                    PosmLoginView()
                }
            }
            .onChange(of: scenePhase) { phase in
                switch phase {
                case .active:
                    locationManagerDelegate.startUpdatingLocation()
                case .background:
                    locationManagerDelegate.stopUpdatingLocation()
                default:
                    break
                }
            }
        }
    }
}



