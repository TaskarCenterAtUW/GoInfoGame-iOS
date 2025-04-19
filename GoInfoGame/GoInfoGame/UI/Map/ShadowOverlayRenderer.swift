//
//  ShadowOverlayRenderer.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 19/04/25.
//

import MapKit
import UIKit


class ShadowOverlayRenderer: MKOverlayRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let shadowOverlay = overlay as? ShadowOverlay else { return }

        let fullRect = self.rect(for: shadowOverlay.boundingMapRect)
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.5))
        context.fill(fullRect)

        context.setBlendMode(.clear)
        context.setAllowsAntialiasing(false)
        context.setShouldAntialias(false)
        
        for rect in shadowOverlay.visibleRects {
            let cutout = self.rect(for: rect).integral
            context.fill(cutout)
        }
        
        context.setBlendMode(.normal)
    }
    
    func addVisibleRect(_ rect: MKMapRect) {
           guard let shadowOverlay = overlay as? ShadowOverlay else { return }
           shadowOverlay.addVisibleRect(rect)
           setNeedsDisplay()
       }
}

class ShadowOverlay: NSObject, MKOverlay {
    let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    let boundingMapRect: MKMapRect = MKMapRect.world
    private(set) var visibleRects: [MKMapRect] = []

    func addVisibleRect(_ rect: MKMapRect) {
        visibleRects.append(rect)
    }
}

