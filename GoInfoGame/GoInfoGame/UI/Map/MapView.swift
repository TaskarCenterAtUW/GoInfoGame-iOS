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
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var coordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    let items: [DisplayUnitWithCoordinate] = AppQuestManager.shared.fetchQuestsFromDB()
    @State private var selectedQuest: DisplayUnit?
    @StateObject var manager = LocationManager()
    @State private var currentLocation: CLLocation?
    
    var btnBack: some View {
        Button(action: {
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
                    .font(Font.title.weight(.medium))
                Text("Back")
            }
        }
    }
    
    var body: some View {
        VStack {
            Map(coordinateRegion: $coordinateRegion, showsUserLocation: true, userTrackingMode: $userTrackingMode, annotationItems: items) { item in
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
            }
            Spacer()
        }
        .sheet(item: $selectedQuest) { selectedQuest in
            if #available(iOS 16.0, *) {
                selectedQuest.parent?.form.presentationDetents(getSheetSize(sheetSize: selectedQuest.sheetSize ?? .MEDIUM))
            } else {
                // Nothing here
            }
        }
        .onAppear {
            manager.locationUpdateHandler = { location in
                self.currentLocation =  CLLocation(latitude: location.latitude, longitude: location.longitude)
//                centerMapOnLocation(location: location)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                btnBack
            }
        }
    }
   
}

extension MapView {
     func centerMapOnLocation(location: CLLocation) {
        let userLocation = location.coordinate
        coordinateRegion.center = userLocation
        let boundingBox = boundingBoxAroundLocation(location: location, distance: 1000)
         let center = CLLocationCoordinate2D(latitude: (boundingBox.minLat + boundingBox.maxLat) / 2, longitude: (boundingBox.minLon + boundingBox.maxLon) / 2)
             let span = MKCoordinateSpan(latitudeDelta: boundingBox.maxLat - boundingBox.minLat, longitudeDelta: boundingBox.maxLon - boundingBox.minLon)
             coordinateRegion = MKCoordinateRegion(center: center, span: span)

         var _: () = AppQuestManager.shared.fetchData(fromBBOx: boundingBox)
    }
     func boundingBoxAroundLocation(location: CLLocation, distance: CLLocationDistance) -> BBox {
        let latDelta = 0.008
        let lonDelta = 0.008
        let coordinate = location.coordinate
        let minLat = coordinate.latitude - latDelta
        let maxLat = coordinate.latitude + latDelta
        let minLon = coordinate.longitude - lonDelta
        let maxLon = coordinate.longitude + lonDelta
        return BBox(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon)
    }
}
#Preview {
    MapView()
}
