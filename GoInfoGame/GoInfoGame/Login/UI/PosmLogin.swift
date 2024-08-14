//
//  PosmLogin.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 05/08/24.
//

import SwiftUI

struct PosmLoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isShowingAlert = false
    @State private var shouldLogin = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Username", text: $username)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal, 40)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
                
                NavigationLink(destination: InitialView(), isActive: $shouldLogin) {
                                    EmptyView()
                                }
                .navigationBarBackButtonHidden(true)
                
                Button(action: {
                   handleLogin()
                }) {
                    Text("Login")
                        .font(.custom("Lato-Bold", size: 20))
                        .foregroundColor(Color.white)
                        .padding()
                        .background( Color(red: 135/255, green: 62/255, blue: 242/255) )
                        .cornerRadius(25)
                }
                .alert(isPresented: $isShowingAlert) {
                    Alert(title: Text("Login Failed"), message: Text("Invalid username or password"), dismissButton: .default(Text("OK")))
                }
            }
        }
    }
    
    func handleLogin() {
        shouldLogin = true
   
//        if username.isEmpty || password.isEmpty {
//            isShowingAlert = true
//        } else {
//         //Navigate to Workspaces
//            shouldLogin = true
//            
//            
//        }
    }
}

#Preview {
    PosmLoginView()
}
