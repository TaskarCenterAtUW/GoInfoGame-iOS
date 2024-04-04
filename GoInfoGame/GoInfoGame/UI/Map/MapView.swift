//
//  MapView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 23/01/24.
//

import SwiftUI
import MapKit
import Combine

struct MapView: View {
    let selectedWorkspace: Workspace?
    @State var trackingMode: MapUserTrackingMode = MapUserTrackingMode.none
    @Environment(\.presentationMode) private var presentationMode
    @AppStorage("isMapFromOnboarding") var isMapFromOnboarding: Bool = false
    @StateObject private var viewModel = MapViewModel()
    @State private var isPresented = false
    
    var body: some View {
            ZStack{
                CustomMap(region: $viewModel.region,
                          trackingMode: $trackingMode,
                          items: viewModel.items,
                          selectedQuest: $viewModel.selectedQuest,
                          isPresented: $isPresented, contextualInfo: { contextualInfo in
                    print(contextualInfo)
                    self.setSubTitleForSideWalk(subTitle: contextualInfo)
                })
                .edgesIgnoringSafeArea(.all)
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                    LoadingView()
                }
            }
            .navigationBarHidden(false)
            .navigationBarItems(leading: EmptyView())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.crop.circle.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        NavigationLink(destination: QuestsListUIView())  {
                            Image(systemName: "list.bullet")
                        }
                        NavigationLink(destination: MeasureSidewalkView()) {
                            Image(systemName: "camera")
                        }
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
        
        .sheet(isPresented: $isPresented, content: {
            let selectedQuest = self.viewModel.selectedQuest
            if #available(iOS 16.0, *) {
                selectedQuest?.parent?.form.presentationDetents(getSheetSize(sheetSize: selectedQuest?.sheetSize ?? .MEDIUM))
            } else {
                // Nothing here
            }
        })
        .onReceive(MapViewPublisher.shared.dismissSheet) { _ in
            viewModel.refreshMapAfterSubmission()
            isPresented = false
        }
        .onAppear(){
            print("selected workspace",selectedWorkspace?.name ?? "")
        }
    }
    
    private func setSubTitleForSideWalk(subTitle: String) {
        if let sidewalk =  self.viewModel.selectedQuest?.parent as? SideWalkWidth {
            sidewalk.subTitle = subTitle
        }
    }
}


public class MapViewPublisher: ObservableObject {
    public let dismissSheet = PassthroughSubject<Bool, Never>()
    static let shared = MapViewPublisher()
    private init() {}
}
