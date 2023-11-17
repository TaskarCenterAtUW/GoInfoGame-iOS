//
//  MapKitViewController.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 16/11/23.
//

import UIKit
import MapKit

class MapKitViewController: UIViewController {
    
    private let locationManager = LocationManager()
    
    private let overpassManager = OverpassRequestManager()
    
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        configureLocationServices()
    }
    
    private func configureLocationServices() {
        locationManager.locationUpdateHandler = { [weak self] coordinate in
            self?.zoomToLatestLocation(with: coordinate)
            
            self?.locationManager.getCurrentLocation { [weak self] result in
                guard let self = self else { return }
                
                let minLatitude = result["minLatitude"]!
                let minLongitude = result["minLongitude"]!
                let maxLatitude = result["maxLatitude"]!
                let maxLongitude = result["maxLongitude"]!
                
                self.overpassManager.makeOverpassRequest(
                    forBoundingBox: minLatitude, minLongitude, maxLatitude, maxLongitude
                ) { [weak self] result in
                    print(result)
                    print("Node Count: \(String(describing: result["nodeCount"]))")
                    print("Way Count: \(String(describing: result["wayCount"]))")
                    print("Relation Count: \(String(describing: result["relCount"]))")
                    
                    self?.locationManager.setOverpassRequestInProgress(false)
                }
            }
        }
    }
    
    
    private func zoomToLatestLocation(with coordinate: CLLocationCoordinate2D) {
        let zoomRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        mapView.setRegion(zoomRegion, animated: true)
    }
    
}
