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
            QuestManager().viewForQeust(quest: annotation.questViewModel ?? StepsRampViewModel())
        }
        .onAppear {
            print(DatabaseConnector.shared.getElementWith(annotation.id) ?? "")
               }
        .background(Color.white)
        .cornerRadius(5)
        .shadow(radius: 2)
    }
}

struct CustomCalloutView_Previews: PreviewProvider {
    static var previews: some View {
        CustomCalloutView(annotation: IdentifiablePointAnnotation(id: 123456,
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), title: "Title",
                                                                  subtitle: "SubTitle", questViewModel: StepsRampViewModel()
        ))
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
