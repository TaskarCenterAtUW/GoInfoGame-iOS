//
//  SceneDelegate.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 09/11/23.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
        
    @AppStorage("loggedIn") private var loggedIn: Bool = false


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
  // guard let _ = (scene as? UIWindowScene) else { return }
        
        
        if loggedIn {
            let contentView = InitialView()
            // Use a UIHostingController as window root view controller.
            if let windowScene = scene as? UIWindowScene {
                let window = UIWindow(windowScene: windowScene)
                window.rootViewController = UIHostingController(rootView: contentView)
                self.window = window
                window.makeKeyAndVisible()
            }
        } else {
            let contentView = PosmLoginView()
            // Use a UIHostingController as window root view controller.
            if let windowScene = scene as? UIWindowScene {
                let window = UIWindow(windowScene: windowScene)
                window.rootViewController = UIHostingController(rootView: contentView)
                self.window = window
                window.makeKeyAndVisible()
            }
        }
#if DEBUG
        if let window = self.window {
            // add the label left bottom of the screen
            let debugLabel = UILabel()
            debugLabel.text = "DEBUG"
            debugLabel.tag = 100
            debugLabel.textAlignment = .center
            debugLabel.font = .boldSystemFont(ofSize: 12)
            debugLabel.textColor = .white
            debugLabel.backgroundColor = Asset.Colors.accentPink.color
            debugLabel.translatesAutoresizingMaskIntoConstraints = false
            
            window.addSubview(debugLabel)
            NSLayoutConstraint.activate([
                debugLabel.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: 0),
                debugLabel.widthAnchor.constraint(equalTo: window.safeAreaLayoutGuide.widthAnchor),
                debugLabel.heightAnchor.constraint(equalToConstant: 14)
            ])
           
        }
#endif
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
         print("Open contexts called")
        // gaurd and get the first URL 
        guard let url = URLContexts.first?.url else { return }

        NotificationCenter.default.post(name: .init("HandleOAuthRedirect"), object: url)

        
    }
    
    

}

