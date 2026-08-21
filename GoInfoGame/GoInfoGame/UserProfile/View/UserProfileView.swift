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

    @StateObject private var viewModel = UserProfileViewModel()
    
    @AppStorage("loggedIn") private var loggedIn: Bool = false
    
    @AppStorage("lowBandwidthMode") private var lowBandwidthMode: Bool = false
    
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
                    }
                    // Colors just this screen's title without touching the shared UINavigationBar.appearance() proxy,
                    // which was leaking into Map's toolbar layout when returning from this screen.
                    ToolbarItem(placement: .principal) {
                        Text(L10n.Localizable.myProfile)
                            .font(.headline)
                            .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
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
