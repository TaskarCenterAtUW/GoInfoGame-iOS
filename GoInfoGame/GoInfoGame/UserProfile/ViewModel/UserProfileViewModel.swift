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
    
    func userFullName() -> String? {
        if let firstName = user?.firstName, let lastName = user?.lastName {
            return "\(firstName) \(lastName)"
        } else if let firstName = user?.firstName {
            return firstName
        } else if let lastName = user?.lastName {
            return lastName
        }
        return nil
    }
    
    func loadCachedUserProfile() {
        if let cachedUser = UserProfileCache.shared.user {
            self.user = cachedUser
        } else {
            fetchUserProfile()
        }
    }
    
    func fetchUserProfile() {
                          
          TDEIAPIManager.shared.fetchUserProfile { [weak self] result in
              switch result {
              case .success(let userprofile):
                  DispatchQueue.main.async {
                      self?.user = userprofile
                      UserProfileCache.shared.cacheUserProfile(userprofile)
                  }
              case .failure(let error):
                  print(error)
              }
          }
      }
}
