//
//  MapViewController.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 25/01/24.
//

import UIKit
import SwiftUI

class MapViewController: UIHostingController<MapView> {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let questListButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(questListButtonTapped))
        navigationItem.rightBarButtonItem = questListButton
        
        let profileButton = UIBarButtonItem(image: UIImage(systemName: "person.crop.circle.fill"), style: .plain, target: self, action: #selector(profileButtonTapped))
        navigationItem.leftBarButtonItem = profileButton
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: MapView())
    }
    
    @objc func questListButtonTapped() {
         let questListView = QuestsListUIView()
         let hostingController = UIHostingController(rootView: questListView)
         present(hostingController, animated: true, completion: nil)
     }
    
    @objc func profileButtonTapped() {
         let profileView = ProfileView()
         let hostingController = UIHostingController(rootView: profileView)
         present(hostingController, animated: true, completion: nil)
     }
}
