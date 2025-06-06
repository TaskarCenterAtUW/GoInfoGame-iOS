//
//  PosmLogin.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 05/08/24.
//

import SwiftUI
import LocalAuthentication

struct PosmLoginView: View {
    
    @ObservedObject var viewModel: PosmLoginViewModel
    
    @State private var selectedEnvironment: AppEnv = .staging
    @State private var showSessionExpiredAlert = false
    
    @State private var route: NavigationRoute?
    
    @State private var shouldShowAlert = false
    
    @State private var showAlert = false
    
    init(viewModel: PosmLoginViewModel = PosmLoginViewModel()) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                VStack(spacing: 20) {
                    Text("GoInfoGame")
                        .font(.custom("Lato-Bold", size: 30))
                        .foregroundColor((Color(red: 135/255, green: 62/255, blue: 242/255)))
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
                    
                    
                    Menu {
                        ForEach(AppEnv.allCases, id: \.self) { environment in
                            Button(action: {
                                selectedEnvironment = environment
                                AppEnvManager.shared.current = environment
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
                            .foregroundColor(Color.white)
                            .padding()
                            .background(Color(red: 135/255, green: 62/255, blue: 242/255))
                            .cornerRadius(25)
                    }
                    .padding(.top, 20)
                    
                    appVersionText
                    
                    if SessionManager.shared.canUseBiometricLogin(for: selectedEnvironment) {
                        Button(action: {
                            AppEnv.shared.current = selectedEnvironment
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
                                    }
                                    
                                case .failure(let message), .unavailable(let message):
                                    print("Biometric login failed: \(message)")
                                    viewModel.hasLoginFailed = true
                                }
                            }
                        }) {
                            Label(BiometricAuthManager.biometricLabelText(), systemImage: BiometricAuthManager.biometricIcon())
                                .font(.custom("Lato-Bold", size: 18))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if case let .error(errorMessage) = viewModel.state {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 8)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    if case .error = viewModel.state {
                                        viewModel.state = .idle
                                    }
                                }
                            }
                    }
                    
                    
                    switch viewModel.state {
                    case .idle:
                        EmptyView()
                    case .loading:
                        ActivityView(activityText: "Loggin In...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.4))
                            .edgesIgnoringSafeArea(.all)
                    case .loaded:
                        EmptyView()
                    case .error(_):
                        EmptyView()
                    }
                    
                    NavigationCoordinator(route: $viewModel.route)
                }
            }
            .onAppear {
                selectedEnvironment = AppEnvManager.shared.current
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SessionExpired"))) { notification in
                showSessionExpiredAlert = true
            }
            .alert("Logout", isPresented: $showSessionExpiredAlert) {
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
}

#Preview("IDLE") {
    PosmLoginView(viewModel: PosmLoginViewModel(state: .idle))
}

#Preview("Loading") {
    PosmLoginView(viewModel: PosmLoginViewModel(state: .loading))
}

#Preview("Error") {
    PosmLoginView(viewModel: PosmLoginViewModel(state: .error("Login Failed")))
}
#Preview("Loaded") {
    PosmLoginView(viewModel: PosmLoginViewModel(state: .loaded))
}
