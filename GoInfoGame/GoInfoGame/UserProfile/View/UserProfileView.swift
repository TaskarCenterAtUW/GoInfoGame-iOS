//
//  UserProfileView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 16/08/24.
//

import SwiftUI

struct UserProfileView: View {

    @StateObject private var viewModel = UserProfileViewModel()
    
    @AppStorage("loggedIn") private var loggedIn: Bool = false
                
    var body: some View {
        Group {
                VStack {
                    Text("My Profile")
                        .font(.custom("Lato-Bold", size: 25))
                    HStack {
                        profileImage
                        VStack (alignment: .leading,spacing: 0){
                            Text(userFullName())
                                .font(.custom("Lato-Bold", size: 20))
                            Text(viewModel.user?.email ?? "")
                                .font(.custom("Lato-Regular", size: 18))
                        }
                        Spacer()
                    }
                    .padding([.bottom], 200)
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
        var fullName = ""
        if let firstName = viewModel.user?.firstName, let lastNane = viewModel.user?.lastName {
            fullName = firstName + " " + lastNane
        }
        return fullName
        
    }
    
    private var profileImage: some View {
        VStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 50, height: 50, alignment: .center)
                .cornerRadius(60)
        }
        .padding([.top], 50)
           
        
    }
        
    private var logOutButton: some View {
        Button {
            _ = KeychainManager.delete(key: "accessToken")
            _ = KeychainManager.delete(key: "username")
        loggedIn = false
            
            if let window = UIApplication.shared.windows.first {
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
