//
//  MapViewControllerView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 03/04/24.
//

import Foundation
import SwiftUI
struct MapViewControllerView : UIViewControllerRepresentable {

     func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    
     }

     func makeUIViewController(context: Context) -> some UIViewController {

        guard let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "MapViewController") as? MapViewController else {
            fatalError("ViewController not implemented in storyboard")
        }
    
        return viewController
     }
}
