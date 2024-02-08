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
    
    @State var trackingMode: MapUserTrackingMode = MapUserTrackingMode.follow
    @StateObject var locationManagerDelegate = LocationManagerDelegate()
    
    @Environment(\.presentationMode) private var presentationMode
    @AppStorage("isMapFromOnboarding") var isMapFromOnboarding: Bool = false
    @StateObject private var viewModel = MapViewModel()
    
    var body: some View {
        
        ZStack {
            Map(coordinateRegion: $viewModel.region, showsUserLocation: true, userTrackingMode: $trackingMode, annotationItems: viewModel.items) { item in
                
                MapAnnotation(coordinate: item.coordinateInfo) {
                    Button {
                        viewModel.selectedQuest = item.displayUnit
                        print(viewModel.selectedQuest as Any, "selectedQuest quest")
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
        .sheet(item: $viewModel.selectedQuest) { selectedQuest in
            if #available(iOS 16.0, *) {
                selectedQuest.parent?.form.presentationDetents(getSheetSize(sheetSize: selectedQuest.sheetSize ?? .MEDIUM))
            } else {
                // Nothing here
            }
        }
    }
}

#Preview {
    MapView()
}
