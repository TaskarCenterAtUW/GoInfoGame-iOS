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
                        self.setSubTitleForSideWalk()
                        isPresented = true
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
    
    private func setSubTitleForSideWalk() {
        if let sidewalk =  self.viewModel.selectedQuest?.parent as? SideWalkWidth {
            sidewalk.subTitle = "This is side walk subTitle"
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
