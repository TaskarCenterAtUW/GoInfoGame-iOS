//
//  UserProfileView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 16/08/24.
//

import SwiftUI
import LocalAuthentication

struct UserProfileView: View {

    @StateObject private var viewModel = UserProfileViewModel()
    
    @AppStorage("loggedIn") private var loggedIn: Bool = false
    
    @AppStorage("useBiometricID") private var useBiometricID: Bool = false
    private var biometricToggleText: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

        switch context.biometryType {
        case .faceID:
            return "Use Face ID for Login"
        case .touchID:
            return "Use Touch ID for Login"
        default:
            return "Use Biometric Login"
        }
    }
                
    var body: some View {
        Group {
                VStack {
                    Text("My Profile")
                        .font(.custom("Lato-Bold", size: 25))
                        .padding(.bottom, 50)
                    HStack(alignment: .center, spacing: 16) {
                        profileImage

                        VStack(alignment: .leading, spacing: 4) {
                            Text(userFullName())
                                .font(.custom("Lato-Bold", size: 20))
                            Text(viewModel.user?.email ?? "")
                                .font(.custom("Lato-Regular", size: 18))
                        }

                        Spacer()
                    }
                    .padding([.bottom], 200)
                    
                    Toggle(isOn: $useBiometricID) {
                        Text(biometricToggleText)
                    }
                    .onChange(of: useBiometricID) { isEnabled in
                        if !isEnabled {
                            SessionManager.shared.logout(environment: APIConfiguration.shared.environment, clearBiometricCreds: true)
                        }
                    }
                    .padding([.bottom], 30)
                    
                    
                    logOutButton
                   
                    Spacer()
                }
                .padding(20)
                .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.fetchUserProfile()
        }
    }
    
    private func userFullName() -> String {
        if let userModel = viewModel.user {
            return userModel.getFullName()
        }
        return ""
        
    }
    
    private var profileImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .frame(width: 50, height: 50)
            .clipShape(Circle())
    }

        
    private var logOutButton: some View {
        Button {
            Utilities.clearAllData()
            
            if let window = UIApplication.window() {
                   window.rootViewController = UIHostingController(rootView: PosmLoginView())
               }
          //  accessToken = nil
        } label: {
            Text("LOGOUT")
                .font(.custom("Lato-Bold", size: 15))
                .foregroundColor(Color.white)
                .padding()
                .background(Color(red: 0.79, green: 0.0, blue: 0.0))
                .cornerRadius(25)
        }
    }
}

#Preview {
    UserProfileView()
}
