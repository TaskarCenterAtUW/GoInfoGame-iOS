//
//  PosmLogin.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 05/08/24.
//

import SwiftUI

import SwiftUI
import LocalAuthentication

struct PosmLoginView: View {

    @ObservedObject var viewModel = PosmLoginViewModel()

    @AppStorage("useBiometricID") private var useBiometricID: Bool = false
    @State private var selectedEnvironment: APIEnvironment = .staging
    @State private var showAlert = false
    
    private var canUseBiometricLogin: Bool {
        let env = selectedEnvironment
        let hasCredentials = KeychainManager.load(.username, for: env) != nil &&
                             KeychainManager.load(.password, for: env) != nil
        return useBiometricID && hasCredentials
    }

    private var biometricLabelText: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType == .faceID ? "Login with Face ID" :
               context.biometryType == .touchID ? "Login with Touch ID" :
               "Login with Biometrics"
    }

    private var biometricIcon: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType == .faceID ? "faceid" :
               context.biometryType == .touchID ? "touchid" : "lock"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 20) {
                    Text("GoInfoGame")
                        .font(.custom("Lato-Bold", size: 30))
                        .foregroundColor(Color(red: 135/255, green: 62/255, blue: 242/255))
                        .padding(.bottom, 50)

                    TextField("Username", text: $viewModel.username)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                        .textInputAutocapitalization(.never)

                    SecureField("Password", text: $viewModel.password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal, 40)

                    Menu {
                        ForEach(APIEnvironment.allCases, id: \.self) { environment in
                            Button(action: {
                                selectedEnvironment = environment
                                APIConfiguration.shared.environment = environment
                            }) {
                                Text(environment.rawValue)
                            }
                        }
                    } label: {
                        HStack {
                            Text("Environment: \(selectedEnvironment.rawValue)")
                                .foregroundColor(.black)
                            Image(systemName: "chevron.down")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 40)

                    Button(action: {
                        viewModel.performLogin()
                    }) {
                        Text("Login")
                            .font(.custom("Lato-Bold", size: 20))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(red: 135/255, green: 62/255, blue: 242/255))
                            .cornerRadius(25)
                    }
                    .padding(.top, 20)

                    if canUseBiometricLogin {
                        Button(action: {
                            viewModel.loginWithBiometricID()
                        }) {
                            Label(biometricLabelText, systemImage: biometricIcon)
                                .font(.custom("Lato-Bold", size: 18))
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 10)
                    }

                    if viewModel.hasLoginFailed {
                        Text("Invalid Credentials")
                            .foregroundColor(.red)
                            .padding(.top, 10)
                    }
                }
                .padding()

                if viewModel.isLoading {
                    ActivityView(activityText: "Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.4))
                        .edgesIgnoringSafeArea(.all)
                }
            }
            .navigationDestination(isPresented: $viewModel.isLoginSuccess) {
                InitialView()
            }
        }
        .alert("Invalid Credentials", isPresented: $viewModel.shouldShowValidationAlert) {
            Button("OK", role: .cancel) { }
        }
        .onAppear {
            selectedEnvironment = APIConfiguration.shared.environment

            if canUseBiometricLogin {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.loginWithBiometricID()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SessionExpired"))) { _ in
            showAlert = true
        }
        .alert("Logout", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your session has expired. Please login again.")
        }
    }
}




#Preview {
    PosmLoginView()
}
