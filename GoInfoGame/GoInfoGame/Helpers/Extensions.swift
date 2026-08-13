//
//  Extension.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 27/11/23.
//

import Foundation
import CoreLocation
import RealmSwift
import ARKit
import SwiftUI
import Combine

extension View {
    func hideKeyboardOnTap() -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                    to: nil, from: nil, for: nil)
                }
        )
    }
}


extension CLLocationCoordinate2D: CustomPersistable {
    
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        (lhs.latitude == rhs.latitude) && (lhs.longitude == rhs.longitude)
    }
    
    public typealias PersistedType = Location
    public init(persistedValue: PersistedType) {
        self.init(latitude: persistedValue.latitude, longitude: persistedValue.longitude)
    }
    public var persistableValue: PersistedType {
        Location(value: [self.latitude,self.longitude])
    }
}

public class Location: EmbeddedObject {
    @Persisted var latitude: Double
    @Persisted var longitude: Double
}
extension CLLocation {
    // Calculate bounding box points given a distance in meters
    func boundingCoordinates(distance: CLLocationDistance) -> (left: CLLocation, bottom: CLLocation, right: CLLocation, top: CLLocation) {
        // Earth radius in meters
        let earthRadius = 6_371_000.0
        
        // Convert distance to radians
        let latRadians = distance / earthRadius
        let lonRadians = distance / (earthRadius * cos(Double.pi * self.coordinate.latitude / 180.0))
        let latDegrees = latRadians * 180.0 / Double.pi
        let lonDegrees = lonRadians * 180.0 / Double.pi
        
        // Calculate bounding box coordinates
        let left = CLLocation(latitude: self.coordinate.latitude, longitude: self.coordinate.longitude - lonDegrees)
        let bottom = CLLocation(latitude: self.coordinate.latitude - latDegrees, longitude: self.coordinate.longitude)
        let right = CLLocation(latitude: self.coordinate.latitude, longitude: self.coordinate.longitude + lonDegrees)
        let top = CLLocation(latitude: self.coordinate.latitude + latDegrees, longitude: self.coordinate.longitude)
        
        return (left, bottom, right, top)
    }
}
// Extension of Array with a method to remove an element
extension Array where Element: Equatable {
    // Check if the element exists in the array
    mutating func removeObject(element: Element) {
        if let index = firstIndex(of: element) {
            // If the element is found, remove it from the array
            remove(at: index)
        }
        
    }
}

extension SCNVector3: Equatable {
    static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
    
    func distance(from vector: SCNVector3) -> Float {
        let distanceX = self.x - vector.x
        let distanceY = self.y - vector.y
        let distanceZ = self.z - vector.z
        
        return sqrtf( (distanceX * distanceX) + (distanceY * distanceY) + (distanceZ * distanceZ))
    }
    
    public static func ==(lhs: SCNVector3, rhs: SCNVector3) -> Bool {
        return (lhs.x == rhs.x) && (lhs.y == rhs.y) && (lhs.z == rhs.z)
    }
}

extension ARSCNView {
    func realWorldVector(screenPos: CGPoint) -> SCNVector3? {
        let planeTestResults = self.hitTest(screenPos, types: [.featurePoint])
        if let result = planeTestResults.first {
            return SCNVector3.positionFromTransform(result.worldTransform)
        }
        
        return nil
    }
}

extension SCNGeometry {
    class func line(from points: [SCNVector3]) -> SCNGeometry {
        let sources = SCNGeometrySource(vertices: points)
        var indices: [Int32] = []
        for i in 0..<points.count {
            indices.append(Int32(i))
        }
        let data = Data(bytes: indices, count: MemoryLayout<Int32>.size * indices.count)
        let element = SCNGeometryElement(data: data, primitiveType: .line, primitiveCount: points.count - 1, bytesPerIndex: MemoryLayout<Int32>.size)
        return SCNGeometry(sources: [sources], elements: [element])
    }
}

extension UIApplication {
    static func window() -> UIWindow? {
        return UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }
    }
    
    var safeAreaBottomInset: CGFloat {
        guard let windowScene = connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: \.isKeyWindow) else {
            return 0
        }
        return window.safeAreaInsets.bottom
    }
}

extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .map { ($0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0 }

        let willHide = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

extension Double {
    func roundedTo7Digits() -> Double {
        (self * 1_000_0000).rounded() / 1_000_0000
    }
}

extension URLRequest {
    mutating func addAuthorizationHeader() {
        if let jwtAccessToken = KeychainManager.load(key: KeychainManager.Keys.accessToken.rawValue) {
            self.setValue("Bearer \(jwtAccessToken)", forHTTPHeaderField: "Authorization")
        }
    }
}

extension View {
    @ViewBuilder
    func applyPresentationSizingPage() -> some View {
        if #available(iOS 18.0, *) {
            self.presentationSizing(.page)
        } else {
            // No-op for older OS, letting the default sizing apply.
            // You can add a fallback here if needed, e.g., using detents.
            self
        }
    }

    /// Lets the presenting view keep receiving touches (pan/zoom/tap) behind a
    /// non-dismiss-disabled sheet, matching Apple Maps' search-sheet behavior.
    @ViewBuilder
    func allowMapInteractionBehindSheet() -> some View {
        if #available(iOS 16.4, *) {
            self.presentationBackgroundInteraction(.enabled)
        } else {
            self
        }
    }
}

private struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

private struct SizedToFitContentModifier: ViewModifier {
    @State private var measuredHeight: CGFloat
    @State private var selectedDetent: PresentationDetent

    init(fallbackHeight: CGFloat) {
        _measuredHeight = State(initialValue: fallbackHeight)
        _selectedDetent = State(initialValue: .height(fallbackHeight))
    }

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: ContentHeightPreferenceKey.self, value: proxy.size.height)
                }
            )
            .onPreferenceChange(ContentHeightPreferenceKey.self) { newHeight in
                // A Set<PresentationDetent> only tells iOS which sizes are *allowed* — it
                // doesn't resize an already-open sheet on its own, so the actual detent has
                // to be driven explicitly via `selection`, or the sheet stays wherever it
                // started (which, before the first measurement lands, would otherwise be a
                // full-screen flash instead of shrinking to fit).
                guard newHeight > 0, abs(newHeight - measuredHeight) > 0.5 else { return }
                measuredHeight = newHeight
                selectedDetent = .height(newHeight)
            }
            .presentationDetents([.height(measuredHeight), .large], selection: $selectedDetent)
    }
}

extension View {
    /// Sizes this view's sheet to fit its own rendered content height, instead of a fixed
    /// `.presentationDetents([.fraction(_:)])` — a screen-height percentage under- or
    /// over-shoots depending on device size, and doesn't grow at larger Dynamic Type sizes,
    /// which is what caused sheet content to get clipped by the sheet boundary before.
    /// Starts at `fallbackHeight` (pass a rough estimate of the content's height at default
    /// text size) so the sheet opens at roughly the right size immediately instead of full
    /// screen, then snaps to the exact measured height as soon as it's available (typically
    /// the same frame). `.large` stays available afterwards as a drag-up option, in case
    /// content grows further (e.g. a live Dynamic Type change) than what was first measured.
    ///
    /// Apply to the content passed to `.sheet { ... }`, after any other modifiers that
    /// affect its size. If the content needs to support more rows/text than reliably fits
    /// on screen, wrap it in `ViewThatFits` with a `ScrollView` fallback branch *before*
    /// applying this — `ViewThatFits` reports whichever branch it actually renders, so this
    /// still measures correctly whether that's the content-hugging branch or, for content
    /// too tall for even a full-screen sheet, the scrolling one. Don't apply this directly
    /// to a bare `ScrollView` with no such fallback: an unconstrained `ScrollView` always
    /// expands to fill whatever height it's offered, so the "measurement" would just be
    /// however much space happened to be on offer, not what the content actually needs.
    func sizedToFitContent(fallbackHeight: CGFloat = 300) -> some View {
        modifier(SizedToFitContentModifier(fallbackHeight: fallbackHeight))
    }

    /// Reports this view's rendered height via `onChange` whenever it changes. Lower-level
    /// building block behind `sizedToFitContent()` — use this directly when only *part* of
    /// a sheet's content should be measured (e.g. everything except an unboundedly-long
    /// list), so that part can be combined with your own sizing logic instead of measuring
    /// (and being thrown off by) the whole thing. See `ManageQuestsView` for an example: it
    /// measures its fixed header/text content this way, then sizes the sheet to that
    /// measured height plus a reserved minimum for its list — so the list always gets at
    /// least that much room, no matter how tall the fixed content above it grows.
    func readHeight(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(key: ContentHeightPreferenceKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(ContentHeightPreferenceKey.self, perform: onChange)
    }
}

// New: helper to focus the accessibility on a view when it appears.
extension View {
    /// Requests VoiceOver focus to this view when it appears (only if VoiceOver is enabled).
    /// Use this on the top-most element in a presented sheet to move VoiceOver focus to it.
    func focusAccessibilityOnAppear() -> some View {
        modifier(_FocusAccessibilityOnAppear())
    }
}

private struct _FocusAccessibilityOnAppear: ViewModifier {
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @AccessibilityFocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .accessibilityFocused($isFocused)
            .onAppear {
                guard voiceOverEnabled else { return }
                // Small delay to ensure the sheet presentation completes and the view is in the hierarchy
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    // Set true to move VoiceOver focus to this element
                    isFocused = true
                    // Post a screen changed notification as a fallback to ensure the system moves focus
                    UIAccessibility.post(notification: .screenChanged, argument: nil)
                }
            }
    }
}

extension CLLocation {
    /**
     Calculates the initial bearing (in degrees) from this location to a target location.
     */
    func bearing(to location: CLLocation) -> Double {
        // Convert latitudes and longitudes from degrees to radians
        let lat1 = self.coordinate.latitude.degreesToRadians
        let lon1 = self.coordinate.longitude.degreesToRadians
        
        let lat2 = location.coordinate.latitude.degreesToRadians
        let lon2 = location.coordinate.longitude.degreesToRadians
        
        // Calculate the difference in longitude
        let dLon = lon2 - lon1
        
        // Spherical trigonometry formula for bearing
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        // Calculate the bearing in radians, then convert to degrees
        let bearingRadians = atan2(y, x)
        var bearingDegrees = bearingRadians.radiansToDegrees
        
        // Normalize the bearing to be between 0 and 360 degrees
        if bearingDegrees < 0 {
            bearingDegrees += 360
        }
        
        return bearingDegrees
    }
}

// Helper extension for conversion
extension Double {
    var degreesToRadians: Double { return self * .pi / 180 }
    var radiansToDegrees: Double { return self * 180 / .pi }
}
