//
//  UserProfileViewModel.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 16/08/24.
//

import Foundation

class UserProfileViewModel: ObservableObject {

    @Published var user: TdeiUserProfile?
    
    init() {
        loadCachedUserProfile()
    }
    
    func loadCachedUserProfile() {
        if let cachedUser = UserProfileCache.shared.user {
            self.user = cachedUser
        } else {
            fetchUserProfile()
        }
    }
    
    func fetchUserProfile() {
        
        let username = KeychainManager.load(key: "username")
        
        if let accessToken = KeychainManager.load(key: "accessToken") {
            ApiManager.shared.performRequest(to: .fetchuserProfile(username!, accessToken), setupType: .userProfile, modelType: TdeiUserProfile.self) { result in
                switch result {
                case .success(let userprofile):
                    print(userprofile)
                    DispatchQueue.main.async {
                        self.user = userprofile
                        UserProfileCache.shared.cacheUserProfile(userprofile)
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
}
