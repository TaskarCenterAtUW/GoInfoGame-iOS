//
//  HomeMapView.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 23/11/23.
//

import SwiftUI
import MapKit

struct HomeMapView: View {
    @StateObject private var homeMapViewModel = HomeMapViewModel()
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    
    
    var body: some View {
        NavigationView {

            MapViewWithOverlays(polylines:$homeMapViewModel.polylines, polygons: $homeMapViewModel.polygons)
            .navigationBarTitle("Home Map")
            .onAppear {
                homeMapViewModel.configureLocationServices()
            }
            .onReceive(homeMapViewModel.$annotations) { newAnnotations in
                // Handle changes to annotations
            }
        }
        
    }
}

#Preview {
    HomeMapView()
}
