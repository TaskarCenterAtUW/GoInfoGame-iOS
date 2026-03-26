//
//  UserProfileView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 16/08/24.
//

import SwiftUI
import LocalAuthentication

struct UserProfileView: View {
    @Environment(\.dismiss) var dismiss

    @StateObject private var viewModel = UserProfileViewModel()
    
    @AppStorage("loggedIn") private var loggedIn: Bool = false
    
    @State private var useBiometricID: Bool = false
        
    @State private var showPasswordAuthenticationView: Bool = false
                        
    var body: some View {
        Group {
            ZStack {
                Asset.Colors.f5F5F5LightGrayBackground.swiftUIColor
                VStack {
                    ZStack {
                        Asset.Colors.e7E3EELightPurpuleBg.swiftUIColor
                            .edgesIgnoringSafeArea(.top)
                            .padding(.top, 0)
                        
                        VStack(alignment: .center, spacing: 16) {
                            profileImage
                            
                            VStack(alignment: .center, spacing: 6) {
                                Text(userFullName())
                                    .font(FontFamily.Lato.bold.swiftUIFont(fixedSize: 20))
                                    .accessibilityLabel("Username \(userFullName())")
                                Text(viewModel.user?.email ?? " ")
                                    .font(FontFamily.Lato.regular.swiftUIFont(fixedSize: 16))
                                    .accessibilityLabel("User email \(viewModel.user?.email ?? "")")
                            }
                            .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                        }
                    }
                    .frame(height: 200)
                    
                    ZStack {
                        Color.white
                        VStack(alignment: .leading, spacing: 25) {
                            Text(L10n.Localizable.preferences.uppercased())
                                .font(FontFamily.Lato.bold.swiftUIFont(size: 14))
                                .foregroundStyle(Asset.Colors._83879BTextFiledTitle.swiftUIColor)
                            
                            if BiometricAuthManager.canEvaluateBiometrics() {
                                BiometricToggleView(isEnabled: $useBiometricID) {status in
                                    if status {
                                        showPasswordAuthenticationView = true
                                    } else {
                                        SessionManager.shared.logout(environment: APIConfiguration.shared.environment, clearBiometricCreds: true)
                                    }
                                }
                            }
                            
                            Line()
                                .stroke(style: .init(dash: [4]))
                                .foregroundStyle(Asset.Colors.ddddddLine.swiftUIColor)
                                .frame(height: 1)
                            
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
                    .clipped()
                }
                .navigationBarBackButtonHidden()
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "arrow.left")
                                .resizable()
                                .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                                .accessibilityLabel(L10n.Localizable.back)
                        }
                    }
                    
                    ToolbarItem(placement: .principal) {
                        Text(L10n.Localizable.myProfile)
                            .font(FontFamily.Lato.bold.swiftUIFont(size: 16))
                            .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
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
          //  accessToken = nil
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundStyle(.white)
                Text("Logout")
                    .font(FontFamily.Lato.bold.swiftUIFont(fixedSize: 16))
                    .foregroundColor(Color.white)
                    
            }
            .padding()
            .background(Asset.Colors.accentPink.swiftUIColor)
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
