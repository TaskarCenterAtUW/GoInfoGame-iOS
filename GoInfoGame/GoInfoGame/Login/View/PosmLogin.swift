//
//  PosmLogin.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 05/08/24.
//

import SwiftUI

struct PosmLoginView: View {
    
    @ObservedObject var viewModel: PosmLoginViewModel
            
    @State private var selectedEnvironment: AppEnv = .staging
    @State private var showSessionExpiredAlert = false
    
    @State private var route: NavigationRoute?
        
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
                    
                    SecureField("Password", text: $viewModel.password)
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
                }
                .padding()
                
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
