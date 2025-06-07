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
                        viewModel.performLogin(with: selectedEnvironment)
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
                            AppEnvManager.shared.current = selectedEnvironment
                            BiometricAuthManager.authenticate(reason: "Login using Face ID") { result in
                                switch result {
                                case .success:
                                    if let username = KeychainManager.load(.username, for: selectedEnvironment),
                                       let password = KeychainManager.load(.password, for: selectedEnvironment) {
                                        
                                        viewModel.username = username
                                        viewModel.password = password
                                        
                                        viewModel.performLogin(with: selectedEnvironment)
                                    } else {
                                        print("Missing credentials in Keychain")
                                        viewModel.state = .error("Missing credentials in Keychain")
                                    }
                                    
                                case .failure(let message), .unavailable(let message):
                                    print("Biometric login failed: \(message)")
                                    viewModel.state = .error(message)
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
                    
                    NavigationCoordinator(route: $viewModel.route)
                }
                if case let .loading(message) = viewModel.state {
                    Color.black.opacity(0.2)
                        .edgesIgnoringSafeArea(.all)
                    VStack {
                        ActivityView(activityText: message.loadingMessage)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
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
    PosmLoginView(viewModel: PosmLoginViewModel(state: .loading(.login)))
}

#Preview("Error") {
    PosmLoginView(viewModel: PosmLoginViewModel(state: .error("Login Failed")))
}
#Preview("Loaded Workspaces") {
    PosmLoginView(viewModel: PosmLoginViewModel(state: .loaded(.login)))
}
