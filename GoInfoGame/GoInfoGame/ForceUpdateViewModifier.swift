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
                title: Text(L10n.Localizable.updateRequired),
                message: Text(L10n.Localizable.ANewVersionOfTheAppIsAvailable.pleaseUpdateToContinueUsingTheApp),
                dismissButton: .default(Text(L10n.Localizable.update), action: openAppStore)
            )
        case .softUpdate:
            return Alert(
                title: Text(L10n.Localizable.updateAvailable),
                message: Text(L10n.Localizable.ANewVersionOfTheAppIsAvailable.wouldYouLikeToUpdateNow),
                primaryButton: .default(Text(L10n.Localizable.update), action: openAppStore),
                secondaryButton: .cancel()
            )
        case .noUpdate:
            // This case should not be reached if showAlert is true
            return Alert(title: Text(""))
        }
    }

    private func openAppStore() {
        var URLString: String = ""
        if forceUpdateManager.appEnvironment == .production {
            URLString = "https://apps.apple.com/app/6749523895"
        } else {
            URLString = "https://testflight.apple.com/join/hpzSaUdQ"
        }
        
        if let url = URL(string: URLString) {
            UIApplication.shared.open(url)
        }
    }
}
