//
//  CustomCallOut.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 25/11/23.
//

import Foundation
import SwiftUI
import MapKit

struct CustomCalloutView: View {
    var annotation: IdentifiablePointAnnotation

    var body: some View {
        VStack {
            Text("Questions coming soon")
                .font(.headline)
                .padding()
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct CustomCalloutView_Previews: PreviewProvider {
    static var previews: some View {
        CustomCalloutView(annotation: IdentifiablePointAnnotation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), title: "Title",
            subtitle: "SubTitle"
        ))
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
