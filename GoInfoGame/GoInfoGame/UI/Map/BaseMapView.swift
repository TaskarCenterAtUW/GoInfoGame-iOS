//
//  BaseMapView.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/23/24.
//

import SwiftUI
import MapKit

struct Location2: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}
struct BaseMapView: View {
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.12), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))

        let locations = [
            Location2(name: "Buckingham Palace", coordinate: CLLocationCoordinate2D(latitude: 51.501, longitude: -0.141)),
            Location2(name: "Tower of London", coordinate: CLLocationCoordinate2D(latitude: 51.508, longitude: -0.076))
        ]
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: locations) { location in
                   MapAnnotation(coordinate: location.coordinate) {
                       Circle()
                           .stroke(.brown, lineWidth: 3)
                           .frame(width: 20, height: 20)
                           
                   }
               }
               .navigationTitle("Map")
               .edgesIgnoringSafeArea(.all)
        
               
        
    }
}

#Preview {
    BaseMapView()
}
