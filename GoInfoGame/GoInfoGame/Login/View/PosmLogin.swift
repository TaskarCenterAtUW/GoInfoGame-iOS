//
//  PosmLogin.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 05/08/24.
//

import SwiftUI
import LocalAuthentication

struct PosmLoginView: View {
    
    @ObservedObject var viewModel = PosmLoginViewModel()
    
    @State private var isShowingAlert = false
    @State private var shouldLogin = false
    
    @State private var shouldShowAlert = false
    
    @State private var selectedEnvironment: APIEnvironment = .production
    @State private var showAlert = false
            
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 20) {
                    HStack {
                        Asset.logo.swiftUIImage
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .padding(-10)
                            .clipShape(Circle())
                            
                        Group {
                            VStack(alignment: .leading) {
                                Text("AVIV")
                                    .font(FontFamily.FONTSPRINGDEMOProximaNova.bold.swiftUIFont(size: 30))
                                Text("ScoutRoute")
                                    .font(FontFamily.FONTSPRINGDEMOProximaNova.bold.swiftUIFont(size: 20))
                            }
                        }
                        .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                    }
                    .padding([.bottom], 50)
                                    
                    TextField("Username", text: $viewModel.username)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                        .textInputAutocapitalization(.never)
                    
                    SecureInputView("Password", text: $viewModel.password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                    #if DEBUG
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
                    
                    #endif
                    Button(action: {
                        APIConfiguration.shared.environment = selectedEnvironment
                        viewModel.performLogin(for: selectedEnvironment)
                    }) {
                        Text("Login")
                            .font(.custom("Lato-Bold", size: 20))
                            .foregroundColor(Color.white)
                            .padding()
                            .background(Asset.Colors.huskyPurple.swiftUIColor)
                            .cornerRadius(25)
                    }
                    .padding(.top, 20)
                    
                    appVersionText
                    
                    if SessionManager.shared.canUseBiometricLogin(for: selectedEnvironment) {
                        Button(action: {
                            APIConfiguration.shared.environment = selectedEnvironment
                            BiometricAuthManager.authenticate(reason: "Login using Face ID") { result in
                                switch result {
                                case .success:
                                    if let username = KeychainManager.load(.username, for: selectedEnvironment),
                                       let password = KeychainManager.load(.password, for: selectedEnvironment) {

                                        viewModel.username = username
                                        viewModel.password = password
                                        
                                        viewModel.performLogin(for: selectedEnvironment)
                                    } else {
                                        print("Missing credentials in Keychain")
                                        viewModel.hasLoginFailed = true
                                        viewModel.loginFailedMessage = "Invalid Credentials"
                                    }

                                case .failure(let message), .unavailable(let message):
                                    print("Biometric login failed: \(message)")
                                    viewModel.hasLoginFailed = true
                                    viewModel.loginFailedMessage = message
                                }
                            }
                        }) {
                            Label(BiometricAuthManager.biometricLabelText(), systemImage: BiometricAuthManager.biometricIcon())
                                .font(.custom("Lato-Bold", size: 18))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if viewModel.hasLoginFailed {
                        Text(viewModel.loginFailedMessage ??  "Invalid Credentials")
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
        .alert(viewModel.errorMessage ?? "Invalid Credentials", isPresented: $viewModel.shouldShowValidationAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Enable Biometric Login?", isPresented: $viewModel.showBiometricPrompt) {
            Button("Enable") {
                viewModel.enableBiometrics(enable: true)
            }
            Button("Not Now", role: .cancel) {
                viewModel.enableBiometrics(enable: false)
            }
        } message: {
            Text("Would you like to use Face ID or Touch ID for faster logins?")
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SessionExpired"))) { notification in
                    showAlert = true
                }
                .alert("Logout", isPresented: $showAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Your session has expired. Please login again")
                }
    }
    
    var appVersionText: Text {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
        return Text("Version \(version) (\(build))")
    }
}

#Preview {
    PosmLoginView()
}
