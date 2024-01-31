//
//  CustomMapView.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/31/24.
//

import SwiftUI
import MapKit

// Use this map to test anything on the maps
struct CustomMapView: View {
    @State private var userTrackingMode: MapUserTrackingMode = .none
    var coordinateRegion: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507212, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.0001, longitudeDelta: 0.0001))
    var body: some View {
        Map(coordinateRegion: .constant(coordinateRegion), showsUserLocation: true, userTrackingMode: $userTrackingMode)
        
    }
}

#Preview {
    CustomMapView()
}
