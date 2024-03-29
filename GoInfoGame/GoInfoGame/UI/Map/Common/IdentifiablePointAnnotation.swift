//
//  IdentifiablePointAnnotation.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 23/11/23.
//

import Foundation
import MapKit

class IdentifiablePointAnnotation: NSObject, Identifiable, MKAnnotation {
    var id: Int
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var questViewModel: Quest?
    
    init(id:Int, coordinate: CLLocationCoordinate2D, title: String? = "", subtitle: String? = "", questViewModel: Quest?) {
        self.id = id
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.questViewModel = questViewModel
    }
}
