//
//  GenericUIViewControllerRepresentable.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 23/11/23.
//

import Foundation
import SwiftUI


struct GenericUIViewControllerRepresentable<UIViewController: UIKit.UIViewController>: UIViewControllerRepresentable {
    let uiViewControllerType: UIViewController.Type
    let configuration: (UIViewController) -> ()

    func makeUIViewController(context: Context) -> UIViewController {
        uiViewControllerType.init()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        configuration(uiViewController)
    }
}

