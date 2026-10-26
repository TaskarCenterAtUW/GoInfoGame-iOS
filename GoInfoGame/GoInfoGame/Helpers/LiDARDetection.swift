//
//  LiDARDetection.swift
//  GoInfoGame
//
//  Created by Prashamsa on 22/04/26.
//

import Foundation
import ARKit

class LiDARDetection {
    static let shared = LiDARDetection()
    
    /// Check if the current device supports LiDAR capability
    /// This uses dynamic ARKit capability detection which automatically supports future devices
    /// No hardcoded device models - will work with all current and future LiDAR-capable devices
    /// - Returns: true if device has LiDAR sensor, false otherwise
    func isLiDARSupported() -> Bool {
        // Check if ARKit is available on this device
        guard ARWorldTrackingConfiguration.isSupported else {
            return false
        }
        
        // Scene reconstruction (a 3D mesh) and scene depth both require the LiDAR sensor, and
        // AutoCapture needs both: its capture requires mesh anchors and its measurements a
        // depth image. `.personSegmentationWithDepth` must not be used here — it is supported
        // on every A12+ iPhone without LiDAR (e.g. iPhone 12, iPhone 17), which showed the
        // AutoCapture question on devices where capturing always fails.
        return ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
            && ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
    }
}
