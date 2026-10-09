//
//  UserProfileView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 16/08/24.
//

import SwiftUI
import LocalAuthentication
import UIKit

struct UserProfileView: View {
    @Environment(\.dismiss) var dismiss

    /// True when opened from the map, i.e. a workspace (and its long form) is loaded.
    var isWorkspaceSelected: Bool = false

    @StateObject private var viewModel = UserProfileViewModel()
    
    @AppStorage("loggedIn") private var loggedIn: Bool = false
    
    @AppStorage("lowBandwidthMode") private var lowBandwidthMode: Bool = false
    
    @AppStorage("showMapZoomButtons") private var showMapZoomButtons: Bool = true
    
    @AppStorage("keepScreenOn") private var keepScreenOn: Bool = false
    
    @State private var useBiometricID: Bool = false
        
    @State private var showPasswordAuthenticationView: Bool = false
                        
    var body: some View {
        Group {
            ZStack {
                Asset.Colors.f5F5F5LightGrayBackground.swiftUIColor
                ScrollView(.vertical, showsIndicators: false) {
                    VStack {
                        ZStack {
                            Asset.Colors.e7E3EELightPurpuleBg.swiftUIColor
                                .edgesIgnoringSafeArea(.top)
                                .padding(.top, 0)
                        
                            VStack(alignment: .center, spacing: 16) {
                                profileImage
                            
                                VStack(alignment: .center, spacing: 6) {
                                    Text(userFullName())
                                        .font(FontFamily.Lato.bold.swiftUIFont(size: 20, relativeTo: .title3))
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .lineLimit(nil)
                                        .minimumScaleFactor(0.5) // safety net for names with no space to wrap on
                                    Text(viewModel.user?.email ?? " ")
                                        .font(FontFamily.Lato.regular.swiftUIFont(size: 16, relativeTo: .body))
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .lineLimit(nil)
                                        .minimumScaleFactor(0.5) // safety net for emails with no space to wrap on
                                }
                                .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                                // Make header content win layout space and be treated as one accessibility element
                                .layoutPriority(2)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Username \(userFullName()) and email ID \(viewModel.user?.email ?? "")")
                                .accessibilityIdentifier(A11yID.Profile.nameAndEmailLabel)
                            }
                        }
                        .frame(minHeight: 200)
                        .zIndex(1)
                    
                        ZStack {
                            Color.white
                            VStack(alignment: .leading, spacing: 25) {
                                Text(L10n.Localizable.preferences.uppercased())
                                    .font(FontFamily.Lato.bold.swiftUIFont(size: 14, relativeTo: .caption))
                                    .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                                
                                if BiometricAuthManager.canEvaluateBiometrics() {
                                    BiometricToggleView(isEnabled: $useBiometricID) {status in
                                        if status {
                                            showPasswordAuthenticationView = true
                                        } else {
                                            SessionManager.shared.logout(environment: APIConfiguration.shared.environment, clearBiometricCreds: true)
                                        }
                                    }
                                    .accessibilityIdentifier(A11yID.Profile.biometricToggle)
                                }
                                
                                Toggle(isOn: $lowBandwidthMode) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(L10n.Localizable.lowBandwidthMode)
                                            .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                                            .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                                        Text(L10n.Localizable.disableQuestImagesToSaveData)
                                            .font(FontFamily.Lato.regular.swiftUIFont(size: 12, relativeTo: .caption))
                                            .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: Asset.Colors.accentPink.swiftUIColor))
                                .accessibilityLabel(L10n.Localizable.lowBandwidthMode)
                                .accessibilityHint(L10n.Localizable.disableQuestImagesToSaveData)
                                .accessibilityIdentifier(A11yID.Profile.lowBandwidthToggle)
                                
                                preferenceToggle(isOn: $showMapZoomButtons,
                                                 title: L10n.Localizable.showMapZoomButtons,
                                                 subtitle: L10n.Localizable.showAndButtonsOnTheMapForZooming)
                                .accessibilityIdentifier(A11yID.Profile.showMapZoomButtonsToggle)

                                preferenceToggle(isOn: $keepScreenOn,
                                                 title: L10n.Localizable.keepScreenOn,
                                                 subtitle: L10n.Localizable.stopTheScreenFromTurningOffWhileTheAppIsOpen)
                                .accessibilityIdentifier(A11yID.Profile.keepScreenOnToggle)
                                .onChange(of: keepScreenOn) { isOn in
                                    UIApplication.shared.isIdleTimerDisabled = isOn
                                }

                                Line()
                                    .stroke(style: .init(dash: [4]))
                                    .foregroundStyle(Asset.Colors.ddddddLine.swiftUIColor)
                                    .frame(height: 1)
                                    .accessibilityHidden(true)

                                Text(L10n.Localizable.debug.uppercased())
                                    .accessibilityLabel(L10n.Localizable.debug)
                                    .font(FontFamily.Lato.bold.swiftUIFont(size: 14, relativeTo: .caption))
                                    .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                                    .accessibilityAddTraits(.isHeader)

                                showQuestFormsRow

                                Line()
                                    .stroke(style: .init(dash: [4]))
                                    .foregroundStyle(Asset.Colors.ddddddLine.swiftUIColor)
                                    .frame(height: 1)
                                    .accessibilityHidden(true)
                                
                                HStack {
                                    Spacer()
                                    logOutButton
                                    Spacer()
                                }
                                
                                Spacer()
                            }
                            .padding()
                        }
                        .padding()
                        .padding(.bottom, 0)
                        .cornerRadius(20)
                    }
                    .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier(A11yID.Profile.scrollView)
                .navigationBarBackButtonHidden()
                .navigationTitle(L10n.Localizable.myProfile)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "arrow.left")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(Rectangle())
                                .accessibilityLabel(L10n.Localizable.back)
                        }
                        .accessibilityIdentifier(A11yID.Profile.backButton)
                    }
                    // Colors just this screen's title without touching the shared UINavigationBar.appearance() proxy,
                    // which was leaking into Map's toolbar layout when returning from this screen.
                    ToolbarItem(placement: .principal) {
                        Text(L10n.Localizable.myProfile)
                            .font(.headline)
                            .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                            .accessibilityIdentifier(A11yID.Profile.titleLabel)
                    }
                }
            }
            .overlay {
                if showPasswordAuthenticationView {
                    PasswordAuthenticationPopupView(viewModel: PasswordAuthenticationViewModel()) {
                        useBiometricID = true
                        showPasswordAuthenticationView = false
                    } onCancel: {
                        useBiometricID = false
                       showPasswordAuthenticationView = false
                    } onFailure: { error in
                        useBiometricID = false
                    }
                }
            }
        }
        .onAppear {
            useBiometricID = SessionManager.shared.isBiometricEnabled(for: APIConfiguration.shared.environment)
            viewModel.fetchUserProfile()
        }
    }
    
    private func userFullName() -> String {
        if let userModel = viewModel.user {
            return userModel.getFullName()
        }
        return " "
        
    }
    
    private var profileImage: some View {
        ZStack {
            Image(systemName: "person.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundStyle(.white)
                .clipShape(Circle())
                .accessibilityLabel(L10n.Localizable.profile)
        }
        .frame(width: 60, height: 60)
        .background{
            LinearGradient(gradient: Gradient(colors: [Asset.Colors._8F57DEProfileIcon.swiftUIColor, Asset.Colors._2D0369ProfileIcon.swiftUIColor,]), startPoint: .top, endPoint: .bottom)
        }
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    private func preferenceToggle(isOn: Binding<Bool>, title: String, subtitle: String) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                    .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                Text(subtitle)
                    .font(FontFamily.Lato.regular.swiftUIFont(size: 12, relativeTo: .caption))
                    .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Asset.Colors.accentPink.swiftUIColor))
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }

    private var showQuestFormsRow: some View {
        NavigationLink(destination: ShowQuestFormsView(isWorkspaceSelected: isWorkspaceSelected)) {
            HStack {
                Text(L10n.Localizable.showQuestForms)
                    .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                    .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(L10n.Localizable.showQuestForms)
        .accessibilityIdentifier(A11yID.Profile.showQuestFormsRow)
    }

    private var logOutButton: some View {
        Button {
            Utilities.clearAllData()
            
            if let window = UIApplication.window() {
                window.rootViewController = UIHostingController(rootView: PosmLoginView(forceUpdateManager: ForceUpdateManager()))
            }
            
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.invalidateRefreshTokenTimer()
            }
          //  accessToken = nil
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundStyle(.white)
                Text("Logout")
                    .font(FontFamily.Lato.bold.swiftUIFont(size: 20, relativeTo: .headline))
                    .foregroundColor(Color.white)
                    
            }
            .padding()
            .background(Asset.Colors.huskyPurple.swiftUIColor)
            .cornerRadius(25)
        }
        .accessibilityIdentifier(A11yID.Profile.logoutButton)
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

#Preview {
    UserProfileView()
}
