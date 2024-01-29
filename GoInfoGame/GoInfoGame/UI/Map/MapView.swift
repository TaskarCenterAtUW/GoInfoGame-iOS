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
    @StateObject private var viewModel = MapViewModel()
    @State private var userTrackingMode: MapUserTrackingMode = .follow

    var btnBack: some View {
        Button(action: {
            if isMapFromOnboarding {
                isMapFromOnboarding = false
                NavigationUtil.popToRootView()
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }) {
            HStack(spacing: 0) {
                Image(systemName: "chevron.left")
                    .scaleEffect(0.50)
                    .font(Font.title.weight(.medium))
                Text("Back")
            }
        }
    }

    var body: some View {
        ZStack {
            Map(coordinateRegion: $viewModel.coordinateRegion, showsUserLocation: true, userTrackingMode: $userTrackingMode, annotationItems: viewModel.items) { item in
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
            }
            
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
        .onAppear {
            viewModel.fetchData()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                btnBack
            }
        }
    }
}
#Preview {
    MapView()
}
