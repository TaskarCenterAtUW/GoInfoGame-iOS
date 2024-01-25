//
//  MapView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 23/01/24.
//

import SwiftUI
import MapKit
import UIKit
import CoreLocation

struct MapView: View {
    @Environment(\.presentationMode) private var presentationMode
    @AppStorage("isMapFromOnboarding") var isMapFromOnboarding: Bool = false
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var coordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    let items: [ DisplayUnitWithCoordinate] = QuestsRepository.shared.displayCoordQuests
    @State var selectedQuest: DisplayUnit?
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
        Map(coordinateRegion: .constant(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))), showsUserLocation: true, userTrackingMode: $userTrackingMode, annotationItems: items) { item in
            MapAnnotation(coordinate: item.coordinateInfo) {
                Button {
                    selectedQuest = item.displayUnit
                    print(selectedQuest as Any,"selectedQuest quest")
                } label: {
                    Image(uiImage: item.displayUnit.parent?.icon ?? UIImage(imageLiteralResourceName: "mapPoint"))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 10)
                        .frame(width: 40, height: 40)
                        .offset(y: -10)
                }
            }
            
        }.sheet(item: $selectedQuest) { selectedQuest in
            if #available(iOS 16.0, *) {
                selectedQuest.parent?.form.presentationDetents(getSheetSize(sheetSize: selectedQuest.sheetSize ?? .MEDIUM))
            } else {
                // Nothing here
            }
            
        }
        .onAppear {
            centerMapOnDefaultLocation()
        }.navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    btnBack
                }
            }
    }
    @State private var locationManager = CLLocationManager()
}


extension MapView {
    private func centerMapOnDefaultLocation() {
        let userLocation = CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321)
        coordinateRegion.center = userLocation
        coordinateRegion.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    }
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
struct CustomLocation: Identifiable {
    let id = UUID()
    let iconName: String
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    MapView()
}
