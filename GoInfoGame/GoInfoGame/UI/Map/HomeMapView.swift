//
//  HomeMapView.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 23/11/23.
//

import SwiftUI
import MapKit

struct HomeMapView: View {
    @StateObject private var homeMapViewModel = HomeMapViewModel()
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    @State private var selectedAnnotation: IdentifiablePointAnnotation?
    @State private var showCallout: Bool = false
    @Environment(\.presentationMode) private var presentationMode
    @AppStorage("isMapFromOboarding") var isMapFromOboarding: Bool = false
    
    var btnBack : some View { Button(action: {
        if isMapFromOboarding {
            isMapFromOboarding = false
            NavigationUtil.popToRootView()
        } else {
            presentationMode.wrappedValue.dismiss()
        }
            }) {
                HStack(spacing: 0){
                    Image(systemName: "chevron.left")
                                .scaleEffect(0.50)
                                .font(Font.title.weight(.medium)
                                )
                    Text("Back")
                }
            }
        }
    
    var body: some View {
        //        NavigationView {
        ZStack {
            MapViewWithOverlays(polylines:$homeMapViewModel.polylines, polygons: $homeMapViewModel.polygons,
                                annotations: $homeMapViewModel.annotations,
                                selectedAnnotation: $selectedAnnotation,
                                showCallout: $showCallout)
            if homeMapViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(2.0)  // Adjust the scale factor as needed
                    .background(Color.white.opacity(0.7)) // Semi-transparent white background
                    .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showCallout) {
            
        }
        .navigationBarTitle("Home Map")
        .onAppear {
            homeMapViewModel.configureLocationServices()
        }
        .onReceive(homeMapViewModel.$annotations) { newAnnotations in
            // Handle changes to annotations
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
    HomeMapView()
}
