//
//  CameraView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 21/02/24.
//

import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraViewController {
        let viewController = CameraViewController()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
    }
}
