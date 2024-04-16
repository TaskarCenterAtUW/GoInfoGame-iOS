//
//  ProfileViewVM.swift
//  GoInfoGame
//
//  Created by Sudula Murali Krishna on 2/21/24.
//

import Foundation
import osmapi

class ProfileViewVM: ObservableObject {
    @Published var user: OSMUserData?
    
    init() {
        let posmConnection = OSMConnection(config: OSMConfig.testPOSM)
        let accessToken = KeychainManager.load(key: "accessToken")
      //  if accessToken != nil {
            posmConnection.getUserDetails { [weak self] result in
                switch result {
                case .success(let userDataResponse):
                    let user = userDataResponse.user
                    print(userDataResponse)
                    DispatchQueue.main.async {
                        self?.user = user
                    }
                case .failure(let error):
                    print("---error", error)
                }
            }
      //  }
    }
        var profileUrl: URL? {
            if let userName = self.user?.displayName {
                return URL(string:OSMConfig.testPOSM.baseUrl.appending("user/").appending(userName))
            }
            return nil
        }
        
        var imageUrl: URL? {
            if let imageString = self.user?.profileImage?.href {
                return URL(string: imageString)
            }
            return nil
        }
    }

