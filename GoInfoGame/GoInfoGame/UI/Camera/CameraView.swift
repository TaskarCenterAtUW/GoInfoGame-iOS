//
//  CameraView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 29/10/24.
//

import Foundation
import UIKit
import SwiftUI
import CoreLocation

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var isPresented: Bool
    @Environment(\.presentationMode) var presentationMode

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        context.coordinator.headingTracker.start()
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    static func dismantleUIViewController(_ uiViewController: UIImagePickerController, coordinator: Coordinator) {
        coordinator.headingTracker.stop()
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        /// Follows the compass while the camera is open, so the photo can record which
        /// way it was taken (sent to Panoramax as GPSImgDirection).
        let headingTracker = HeadingTracker()

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                image.captureHeading = headingTracker.headingAtShutter
                parent.capturedImage = image
            }
            headingTracker.stop()
            parent.isPresented = false // Close the camera view after capturing
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            headingTracker.stop()
            parent.isPresented = false
        }
    }
}

/// The device's true-north compass heading while the camera is open.
///
/// Core Location reports the direction the back camera faces when the phone is held upright,
/// and `headingOrientation` keeps that right in landscape. The heading is frozen when the
/// shutter is pressed (UIImagePickerController posts "_UIImagePickerControllerUserDidCaptureItem"),
/// so turning the phone on the Use Photo screen doesn't change it. If that notification never
/// comes, the latest reading is used instead.
final class HeadingTracker: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    private var latestHeading: Double?
    private var frozenHeading: Double?
    private var observers: [NSObjectProtocol] = []

    /// The heading when the shutter was pressed, else the latest one; nil when no
    /// trustworthy reading was available (no compass, uncalibrated, location off).
    var headingAtShutter: Double? { frozenHeading ?? latestHeading }

    override init() {
        super.init()
        manager.delegate = self
        manager.headingFilter = 1
    }

    func start() {
        guard CLLocationManager.headingAvailable(), observers.isEmpty else { return }
        latestHeading = nil
        frozenHeading = nil
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        updateHeadingOrientation()
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil,
                                            queue: .main) { [weak self] _ in
            self?.updateHeadingOrientation()
        })
        observers.append(center.addObserver(forName: Notification.Name("_UIImagePickerControllerUserDidCaptureItem"),
                                            object: nil, queue: .main) { [weak self] _ in
            self?.frozenHeading = self?.latestHeading
        })
        observers.append(center.addObserver(forName: Notification.Name("_UIImagePickerControllerUserDidRejectItem"),
                                            object: nil, queue: .main) { [weak self] _ in
            self?.frozenHeading = nil   // "Retake": the next shutter press decides again
        })
        manager.startUpdatingHeading()
    }

    func stop() {
        guard !observers.isEmpty else { return }
        manager.stopUpdatingHeading()
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    deinit {
        stop()
    }

    private func updateHeadingOrientation() {
        // Face up/down and unknown keep the last useful orientation.
        switch UIDevice.current.orientation {
        case .portrait: manager.headingOrientation = .portrait
        case .portraitUpsideDown: manager.headingOrientation = .portraitUpsideDown
        case .landscapeLeft: manager.headingOrientation = .landscapeLeft
        case .landscapeRight: manager.headingOrientation = .landscapeRight
        default: break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // trueHeading is negative when it can't be worked out (e.g. no location fix), and a
        // negative accuracy means the reading is invalid; send nothing rather than a guess.
        guard newHeading.headingAccuracy >= 0, newHeading.trueHeading >= 0 else { return }
        latestHeading = PhotoHeading.normalized(newHeading.trueHeading)
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        false // never cover the camera with the calibration prompt
    }
}
