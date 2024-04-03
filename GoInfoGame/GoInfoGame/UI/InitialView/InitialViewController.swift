//
//  InitialViewController.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 03/04/24.
//

import Foundation
import SwiftUI
class InitialViewController: UIHostingController<InitialView> {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: InitialView())
    }
}
