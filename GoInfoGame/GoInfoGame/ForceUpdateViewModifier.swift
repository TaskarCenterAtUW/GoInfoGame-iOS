//
//  ForceUpdateViewModifier.swift
//  GoInfoGame
//
//  Created by Prashamsa on 13/10/25.
//

import Foundation
import SwiftUI

struct ForceUpdateViewModifier: ViewModifier {
    @ObservedObject var forceUpdateManager: ForceUpdateManager
    @State private var showAlert = false

    func body(content: Content) -> some View {
        content
            .onReceive(forceUpdateManager.updateCheckCompleted) { _ in
                showAlert = forceUpdateManager.appUpdateInfo != .noUpdate
            }
            .alert(isPresented: $showAlert) {
                createAlert()
            }
    }

    private func createAlert() -> Alert {
        switch forceUpdateManager.appUpdateInfo {
        case .forceUpdate:
            return Alert(
                title: Text("Update Required"),
                message: Text("A new version of the app is available. Please update to continue using the app."),
                dismissButton: .default(Text("Update"), action: openAppStore)
            )
        case .softUpdate:
            return Alert(
                title: Text("Update Available"),
                message: Text("A new version of the app is available. Would you like to update now?"),
                primaryButton: .default(Text("Update"), action: openAppStore),
                secondaryButton: .cancel()
            )
        case .noUpdate:
            // This case should not be reached if showAlert is true
            return Alert(title: Text(""))
        }
    }

    private func openAppStore() {
        if let url = URL(string: "https://apps.apple.com/app/6749523895") {
            UIApplication.shared.open(url)
        }
    }
}
