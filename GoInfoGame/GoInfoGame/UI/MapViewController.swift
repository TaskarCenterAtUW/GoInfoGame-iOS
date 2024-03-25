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
        self.title = ""

        // Do any additional setup after loading the view.
        
        let questListButton = UIBarButtonItem(image: UIImage(systemName: "list.bullet"), style: .plain, target: self, action: #selector(questListButtonTapped))
        
        let widthDemoButton = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(widthDemoButtonTapped))
        navigationItem.rightBarButtonItems = [questListButton, widthDemoButton]

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
        navigationController?.pushViewController(hostingController, animated: true)
     }
    
    @objc func widthDemoButtonTapped() {
        let measureSidewalkView = MeasureSidewalkView()
         let hostingController = UIHostingController(rootView: measureSidewalkView)
         present(hostingController, animated: true, completion: nil)
     }
}
