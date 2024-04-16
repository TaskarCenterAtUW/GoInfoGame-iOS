//
//  ProfileView.swift
//  GoInfoGame
//
//  Created by Sudula Murali Krishna on 2/21/24.
//

import Foundation
import SwiftUI
import osmapi

struct ProfileView: View {
    
    @State private var isSafariViewControllerPresented = false
    
    @State var osmApiUrl: String?
    
    @State private var accessToken: String?
   
    var body: some View {
        return
            VStack {
                LoggedInView(isSafariViewControllerPresented: $isSafariViewControllerPresented, accessToken: $accessToken)
                
                
                
                //TODO: TO be considered later
               // if accessToken != nil {
//                    LoggedInView(isSafariViewControllerPresented: $isSafariViewControllerPresented, accessToken: $accessToken)
//                } else {
//                    LoginView(isSafariViewControllerPresented: $isSafariViewControllerPresented) { accessToken in
//                        self.accessToken = accessToken
//                    }
//                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("HandleOAuthRedirect"))) { notification in
                if let url = notification.object as? URL {
                    
                    // Handle the URL here and call the function in OAuthViewController
                    OAuthViewController().getAccessTokenFor(url: url, completion: { accessToken in
                        let osmConnection = OSMConnection()
                        
                        osmConnection.getUserDetails { result in
                            switch result {
                            case .success(let user):
                                print(user)
                                isSafariViewControllerPresented = false
                                self.accessToken = accessToken
                            case .failure(_):
                                print("error")
                            }
                        }
                    })
                }
            }
            .onAppear {
                if let token = KeychainManager.load(key: "accessToken") {
                    accessToken = token
                }
            }
        }
}

#Preview {
    ProfileView()
}

struct LoggedInView: View {
    
    @ObservedObject private var viewModel = ProfileViewVM()
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    @Binding var isSafariViewControllerPresented: Bool
        
   @Binding var accessToken: String?
    
    var body: some View {
        Group {
        //    if accessToken != nil {
                VStack {
                    Text("My Profile")
                        .font(.title)
                        
                    HStack {
                        profileImage
                        VStack (alignment: .leading,spacing: 0){
                            Text(viewModel.user?.displayName ?? "")
                                .font(.system(size: 20, weight: .semibold))
                            HStack {
                                Image(systemName: "star.fill")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                Text("\(viewModel.user?.changesets.count ?? 0)")
                                    .font(.title)
                            }
                        }
                        Spacer()
                    }
                    HStack {
                        profileButton
                      //  Spacer()
                       // logOutButton
                    }
                    Divider().padding()
                    Spacer()
                }
                .padding(20)
                .navigationBarTitleDisplayMode(.inline)
//            } else {
//                LoginView(isSafariViewControllerPresented: $isSafariViewControllerPresented) { token in
//                    accessToken = token
//                }
//            }
        }
    }
    
    @ViewBuilder
    private var profileImage: some View {
        if self.viewModel.imageUrl == nil {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 80, height: 80, alignment: .center)
                .cornerRadius(60)
        }else {
            AsyncImage(url: self.viewModel.imageUrl) { phase in
                if let image = phase.image {
                    image.resizable()
                } else if phase.error != nil {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                } else {
                    ProgressView().progressViewStyle(.circular)
                }
            }
            .frame(width: 120, height: 120, alignment: .center)
            .cornerRadius(60)
        }
    }
    
    private var profileButton: some View {
        Button {
            if let url = viewModel.profileUrl {
                openURL(url)
            }
        } label: {
            HStack {
                Image(systemName: "tray.and.arrow.up.fill")
                Text("OSM Profile")
            }
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold))
            .frame(width: 180, height: 50)
            .background(.black)
            .cornerRadius(5)
        }
    }
    
    private var logOutButton: some View {
        Button {
            _ = KeychainManager.delete(key: "accessToken")
            accessToken = nil
        } label: {
            Text("LOGOUT")
                .foregroundColor(.black)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 50)
                .cornerRadius(15)
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.black)
                }
        }
    }
}

struct LoginView: View {
    
    @Binding private var isSafariViewControllerPresented: Bool
    var loginAction: (String) -> Void
    
    public init(isSafariViewControllerPresented: Binding<Bool>, loginAction: @escaping (String) -> Void) {
           _isSafariViewControllerPresented = isSafariViewControllerPresented
           self.loginAction = loginAction
       }
    
    var body: some View {
        VStack {
            Button("LOGIN") {
                self.isSafariViewControllerPresented = true
            }
            .foregroundColor(.white)
            .font(.headline)
            .padding()
            .frame(width: UIScreen.main.bounds.width / 2)
            .background(Color.blue)
            .cornerRadius(10)
            .sheet(isPresented: $isSafariViewControllerPresented) {
                OAuthViewController()
            }
            .navigationBarHidden(false)
            .padding()
        }
        
    }
    
}
