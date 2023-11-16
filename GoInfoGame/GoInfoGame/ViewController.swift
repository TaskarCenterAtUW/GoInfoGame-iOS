//
//  ViewController.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 09/11/23.
//

import UIKit

class ViewController: UIViewController {
    
    @IBAction func onViewMapBtnClicked(_ sender: Any) {
        let vc = (storyboard?.instantiateViewController(identifier: "MapKitViewController"))! as MapKitViewController
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
   

    override func viewDidLoad() {
        super.viewDidLoad()
        


    }
    


}

