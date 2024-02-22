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
        let posmConnection = OSMConnection(config: OSMConfig.test,userCreds: OSMLogin.test)
        posmConnection.getUserDetails() { [weak self]result in
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
    }
}
