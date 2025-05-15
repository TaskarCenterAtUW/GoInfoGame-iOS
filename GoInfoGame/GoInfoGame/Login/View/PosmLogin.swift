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
    
    @State private var selectedEnvironment: APIEnvironment = .staging
    @State private var showAlert = false
    
    @AppStorage("useBiometricID") private var useBiometricID: Bool = false
        
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
                        APIConfiguration.shared.environment = selectedEnvironment
                        viewModel.performLogin(for: selectedEnvironment)
                    }) {
                        Text("Login")
                            .font(.custom("Lato-Bold", size: 20))
                            .foregroundColor(Color.white)
                            .padding()
                            .background(Color(red: 135/255, green: 62/255, blue: 242/255))
                            .cornerRadius(25)
                    }
                    .padding(.top, 20)
                    
                    if SessionManager.shared.canUseBiometricLogin(for: selectedEnvironment) {
                        Button(action: {
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
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SessionExpired"))) { notification in
                    showAlert = true
                }
                .alert("Logout", isPresented: $showAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Your session has expired. Please login again")
                }
    }
}

#Preview {
    PosmLoginView()
}
