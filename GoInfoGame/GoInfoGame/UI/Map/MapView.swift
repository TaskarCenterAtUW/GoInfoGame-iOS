//
//  MapView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 23/01/24.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct MapView: View {
    
    @State var trackingMode: MapUserTrackingMode = MapUserTrackingMode.none
    @StateObject var locationManagerDelegate = LocationManagerDelegate()
    
    @Environment(\.presentationMode) private var presentationMode
    @AppStorage("isMapFromOnboarding") var isMapFromOnboarding: Bool = false
    @StateObject private var viewModel = MapViewModel()
    @State private var isPresented = false

    var body: some View {
        
        ZStack {
            Map(coordinateRegion: $viewModel.region, showsUserLocation: true, userTrackingMode: $trackingMode, annotationItems: viewModel.items) { item in
                
                MapAnnotation(coordinate: item.coordinateInfo) {
                    Button {
                        viewModel.selectedQuest = item.displayUnit
                        isPresented = true
                        print(viewModel.selectedQuest as Any, "selectedQuest quest")
                        let distance = calculateDistance(selectedAnnotation: item.coordinateInfo)
                        print("Distance from the user is \(distance) meters" )
                        
                        let direction = inferDirection(selectedAnnotation: item.coordinateInfo)
                        print("Direction is \(direction)")
                    
                        inferAddress { address in
                            if let address = address {
                                print("This waylit is on \(address) at \(distance) meters away on \(direction)")
                            } else {
                                
                            }
                        }
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
            }.ignoresSafeArea()
            
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                LoadingView()
            }
        }
        .sheet(isPresented: $isPresented, content: {
            let selectedQuest = self.viewModel.selectedQuest
            if #available(iOS 16.0, *) {
                selectedQuest?.parent?.form.presentationDetents(getSheetSize(sheetSize: selectedQuest?.sheetSize ?? .MEDIUM))
            } else {
                // Nothing here
            }
        })
        .onReceive(MapViewPublisher.shared.dismissSheet) { _ in
            isPresented = false
        }
    }
    
    // calculate distance between user current location and selected annotation
    func calculateDistance(selectedAnnotation: CLLocationCoordinate2D) -> CLLocationDistance {
        let userCurrentLocation = locationManagerDelegate.locationManager.location!.coordinate
        let fromLocation = CLLocation(latitude: userCurrentLocation.latitude, longitude: userCurrentLocation.longitude)
        let toLocation = CLLocation(latitude: selectedAnnotation.latitude, longitude: selectedAnnotation.longitude)
        return CLLocationDistance(Int(fromLocation.distance(from: toLocation)))
    }
    
    // infer direction
    func inferDirection(selectedAnnotation: CLLocationCoordinate2D) -> String {
        let userCurrentLocation = locationManagerDelegate.locationManager.location!.coordinate
        let userLocationPoint = MKMapPoint(userCurrentLocation)
        let destinationPoint = MKMapPoint(selectedAnnotation)
        let angleRadians = atan2(destinationPoint.y - userLocationPoint.y, destinationPoint.x - userLocationPoint.x)
        var angleDegrees = angleRadians * 180 / .pi
        angleDegrees += 90 // Adjust to be relative to north
        
        if angleDegrees < 0 {
            angleDegrees += 360
        } else if angleDegrees >= 360 {
            angleDegrees -= 360
        }
        
        angleDegrees = (angleDegrees * 10).rounded() / 10
        
        var direction = ""
        
        print("Angle for inferDirection (degrees): \(angleDegrees)")

        if angleDegrees >= 337.5 || angleDegrees < 22.5 {
            direction = "north"
        } else if angleDegrees >= 22.5 && angleDegrees < 67.5 {
            direction = "northeast"
        } else if angleDegrees >= 67.5 && angleDegrees < 112.5 {
            direction = "east"
        } else if angleDegrees >= 112.5 && angleDegrees < 157.5 {
            direction = "southeast"
        } else if angleDegrees >= 157.5 && angleDegrees < 202.5 {
            direction = "south"
        } else if angleDegrees >= 202.5 && angleDegrees < 247.5 {
            direction = "southwest"
        } else if angleDegrees >= 247.5 && angleDegrees < 292.5 {
            direction = "west"
        } else {
            direction = "northwest"
        }
        return direction
    }
    
    // infer address from user location coordinates
    func inferAddress(completion: @escaping (String?) -> Void) {
        let userCurrentLocation = locationManagerDelegate.locationManager.location!
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(userCurrentLocation) { placemarks, error in
            guard let placemark = placemarks?.first else {
                completion(nil)
                return
            }
            var addressComponents: [String] = []
            if let streetNumber = placemark.subThoroughfare {
                addressComponents.append(streetNumber)
            }
            if let streetName = placemark.thoroughfare {
                addressComponents.append(streetName)
            }
            
            let address = addressComponents.joined(separator: ", ")
            completion(address)
        }
    }
}

#Preview {
    MapView()
}


public class MapViewPublisher: ObservableObject {
    public let dismissSheet = PassthroughSubject<Bool, Never>()
    static let shared = MapViewPublisher()
    private init() {}
}


extension CLPlacemark {

    var address: String? {
        if let name = name {
            var result = name

            if let street = thoroughfare, !street.isEmpty {
                result += ", \(street)"
            }

            if let city = locality {
                result += ", \(city)"
            }

            if let country = country {
                result += ", \(country)"
            }

            return result
        }

        return nil
    }

}
