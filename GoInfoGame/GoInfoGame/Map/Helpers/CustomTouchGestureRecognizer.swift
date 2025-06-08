//
//  CustomTouchGestureRecognizer.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 08/06/25.
//

import Foundation
import UIKit

class CustomTouchGestureRecognizer: UIGestureRecognizer {
    weak var annotation: DisplayUnitAnnotation?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .began
        if let view = view as? CustomAnnotationView, let annotation = view.annotation as? DisplayUnitAnnotation {
            self.annotation = annotation
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .ended
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
    }
}
