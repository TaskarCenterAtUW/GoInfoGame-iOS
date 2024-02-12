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
    }
    required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder, rootView: MapView())
        }
}
