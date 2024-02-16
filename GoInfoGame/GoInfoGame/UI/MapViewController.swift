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
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: MapView())
    }
    
    @objc func questListButtonTapped() {
         let questListView = QuestsListUIView()
         let hostingController = UIHostingController(rootView: questListView)
         present(hostingController, animated: true, completion: nil)
     }
}
