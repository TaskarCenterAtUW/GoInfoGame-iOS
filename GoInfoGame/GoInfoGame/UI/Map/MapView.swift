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
    
    @State private var shouldShowPolyline = true
    @State private var isSyncing = false
    @StateObject var contextualInfo = ContextualInfo.shared
    
    @AppStorage("baseUrl") var baseUrl = ""
        
    var body: some View {
            ZStack{
                CustomMap(region: $viewModel.region,
                          trackingMode: $trackingMode,
                          items: viewModel.items,
                          selectedQuest: $viewModel.selectedQuest,
                          shouldShowPolyline: $shouldShowPolyline,
                          isPresented: $isPresented, contextualInfo: { contextualInfo in
                    print(contextualInfo)
                    self.setContextualInfo(contextualinfo: contextualInfo)
                })
                .id(viewModel.refreshMap)
                .edgesIgnoringSafeArea(.all)
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                   ActivityView(activityText: "Looking for quests...")
                }
            }
            .environmentObject(contextualInfo)
            .navigationBarHidden(false)
            .navigationBarItems(leading: EmptyView())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.crop.circle.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSyncing {
                        ProgressView()
                    }else{
                        EmptyView()
                    }
                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    HStack {
//                        NavigationLink(destination: QuestsListUIView())  {
//                            Image(systemName: "list.bullet")
//                        }
//                        NavigationLink(destination: MeasureSidewalkView()) {
//                            Image(systemName: "camera")
//                        }
//                    }
//                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
        
        .sheet(isPresented: $isPresented, content: {
            let selectedQuest = self.viewModel.selectedQuest
            if #available(iOS 16.0, *) {
                selectedQuest?.parent?.form.presentationDetents(getSheetSize(sheetSize: selectedQuest?.sheetSize ?? .MEDIUM))
                    .environmentObject(contextualInfo)
                    .interactiveDismissDisabled()
                    .onAppear(perform: {
                        shouldShowPolyline = true
                    })
            } else {
                // Nothing here
            }
        })
        .onReceive(MapViewPublisher.shared.dismissSheet) { scenario in
            
//            isPresented = false
            switch scenario {
            case .dismissed:
                shouldShowPolyline = false
            case .submitted:
                viewModel.refreshMapAfterSubmission()
                shouldShowPolyline = false
            case .syncing:
                isSyncing = true
                print("syncing")
            case .synced:
                isSyncing = false
                print("synced")
            }
        }
        .onAppear(){
            print("selected workspace",selectedWorkspace?.title ?? "")
            self.baseUrl = "https://workspaces-osm-stage.sidewalks.washington.edu"
        }
    }
    
    private func setContextualInfo(contextualinfo: String) {
        contextualInfo.info = contextualinfo
        
    }
}


public class MapViewPublisher: ObservableObject {
    public let dismissSheet = PassthroughSubject<SheetDismissalScenario, Never>()
    static let shared = MapViewPublisher()
    private init() {}
}

public enum SheetDismissalScenario {
    case dismissed
    case submitted
    case syncing
    case synced
}

//TODO: Move to a new file
class ContextualInfo: ObservableObject {
    static let shared = ContextualInfo()
    
    @Published var info: String = "Contextual info appears here"
    
    private init() {}
}
