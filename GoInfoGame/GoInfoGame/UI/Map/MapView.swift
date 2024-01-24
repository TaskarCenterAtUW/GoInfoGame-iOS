//
//  MapView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 23/01/24.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @Environment(\.presentationMode) private var presentationMode
    @AppStorage("isMapFromOnboarding") var isMapFromOnboarding: Bool = false
    @State private var coordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    var btnBack : some View { Button(action: {
        if isMapFromOnboarding {
            isMapFromOnboarding = false
            NavigationUtil.popToRootView()
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }) {
        HStack(spacing: 0){
            Image(systemName: "chevron.left")
                .scaleEffect(0.50)
                .font(Font.title.weight(.medium)
                )
            Text("Back")
        }
    }}
    var body: some View {
        Map(coordinateRegion: $coordinateRegion, showsUserLocation: true, userTrackingMode: $userTrackingMode)
            .onAppear {
                requestLocation()
            }.navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    btnBack
                }
            }
    }

    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var locationManager = CLLocationManager()
}


extension MapView {
    func centerMapOnLocation(location: CLLocation) {
        let region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        coordinateRegion = region
    }

    private func requestLocation() {
        let coordinator = LocationManagerCoordinator(parent: self)
        locationManager.delegate = coordinator
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
}

#Preview {
    MapView()
}
