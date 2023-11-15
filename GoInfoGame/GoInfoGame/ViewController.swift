//
//  ViewController.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 09/11/23.
//

import UIKit

class ViewController: UIViewController {
    
    let overpassManager = OverpassRequestManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        overpassManager.makeOverpassRequest(forBoundingBox: 17.4554726, 78.3709717, 17.4607127, 78.3764648) { result in
            print(result)
            print("Node Count: \(String(describing: result["nodeCount"]))")
            print("Way Count: \(String(describing: result["wayCount"]))")
            print("Relation Count: \(String(describing: result["relCount"]))")

        }

    }
    


}

