//
//  CustomAnnotationView.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 19/12/23.
//

import Foundation
import SwiftUI
import MapKit

class CustomAnnotationView: MKAnnotationView {
    private var hostingController: UIHostingController<AnyView>?
    private var dynamicImage: UIImage?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureUI()
    }

    private func configureUI() {
        // Set the frame size based on your requirements
        frame = CGRect(x: 0, y: 0, width: 40, height: 40)

        // Create a SwiftUI view
        let swiftUIView = CustomAnnotationPointView()

        // Create a hosting controller for the SwiftUI view
        hostingController = UIHostingController(rootView: AnyView(swiftUIView))
        hostingController?.view.backgroundColor = .clear

        // Add the hosting controller's view as a subview
        if let hostingView = hostingController?.view {
            addSubview(hostingView)
            hostingView.frame = bounds
        }

        updateDynamicImage(dynamicImage)
    }

    func updateDynamicImage(_ image: UIImage?) {
        dynamicImage = image
        hostingController?.rootView = AnyView(CustomAnnotationPointView(dynamicImage: dynamicImage))
    }
}
