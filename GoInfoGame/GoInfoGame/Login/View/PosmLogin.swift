//
//  PosmLogin.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 05/08/24.
//

import SwiftUI

struct PosmLoginView: View {
    
    @ObservedObject var viewModel = PosmLoginViewModel()
    
    @State private var isShowingAlert = false
    @State private var shouldLogin = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Username", text: $viewModel.username)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
                
                SecureField("Password", text: $viewModel.password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                
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
                if viewModel.isLoggedIn {
                    NavigationLink(destination: InitialView(), isActive: $viewModel.isLoggedIn) {
                        EmptyView()
                    }
                    .navigationBarBackButtonHidden(true)
                }
            }
        }
    }
    
}

#Preview {
    PosmLoginView()
}
