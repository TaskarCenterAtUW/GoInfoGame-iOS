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
            MapViewCoordinator(region: $viewModel.region,
                          trackingMode: $trackingMode,
                          items: viewModel.items,
                          selectedQuest: $viewModel.selectedQuest,
                          isPresented: $isPresented,
                          isLoading: viewModel.isLoading)
                .edgesIgnoringSafeArea(.all)
            
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
}

#Preview {
    MapView()
}


public class MapViewPublisher: ObservableObject {
    public let dismissSheet = PassthroughSubject<Bool, Never>()
    static let shared = MapViewPublisher()
    private init() {}
}
