//
//  InitialViewController.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 03/04/24.
//
// InitialViewController - Hosting controller for InitialView
import Foundation
import SwiftUI
class InitialViewController: UIHostingController<PosmLoginView> {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: PosmLoginView())
    }
}
