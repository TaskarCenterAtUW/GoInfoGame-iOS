//
//  LoginViewController.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 20/11/23.
//

import UIKit

class LoginViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func loginMethod(_ sender: Any?) {
        
        if OAuthManager.shared.isAuthorized() {
            // User is already authorized, fetch user details or perform other actions
            OAuthManager.shared.getUserDetails { userDetails in
                // Handle user details or perform other actions
            }
        } else {
            // User is not authorized, request access from the user
            OAuthManager.shared.requestAccessFromUser(withVC: self) { [weak self] result in
                self?.handleAuthorizationResult(result)
            }
        }
    }
    
    // Handle the result of the authorization request
       private func handleAuthorizationResult(_ result: Result<Void, Error>) {
           switch result {
           case .success:
               // Authorization successful, fetch user details or perform other actions
               OAuthManager.shared.getUserDetails { userDetails in
                   // Handle user details or perform other actions
               }
           case .failure(let error):
               // Authorization failed, handle the error
               print("Authorization failed with error: \(error.localizedDescription)")
           }
       }
    
}
