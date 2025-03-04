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
    @State var trackingMode: MapUserTrackingMode = MapUserTrackingMode.follow
    @Environment(\.presentationMode) private var presentationMode
    @AppStorage("isMapFromOnboarding") var isMapFromOnboarding: Bool = false
    @StateObject private var viewModel = MapViewModel()
    @State private var isPresented = false
    
    @State private var shouldShowPolyline = true
    @State private var isSyncing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertIcon = ""
    @StateObject var contextualInfo = ContextualInfo.shared
    
    @State private var selectedDetent: PresentationDetent = .fraction(0.8)
    
    @State private var showPopover = false
    
    @AppStorage("baseUrl") var baseUrl = ""
    
    @State private var useBingMaps = false
    
    @State private var tappedCoordinate: CLLocationCoordinate2D? = nil
    
    @State private var showMapLongPressedSheet = false
    
    @State private var showAddFeatureSheet = false
    
    @State private var showCreateNoteSheet = false
                
    var body: some View {
            ZStack{
                CustomMap(region: viewModel.region,
                          userLocation: viewModel.userlocation,
                          trackingMode: $trackingMode,
                          items: $viewModel.items,
                          selectedQuest: $viewModel.selectedQuest,
                          shouldShowPolyline: $shouldShowPolyline,
                          
                          isPresented: $isPresented, contextualInfo: { contextualInfo in
                    print(contextualInfo)
                    selectedDetent = .fraction(0.8)
                    self.setContextualInfo(contextualinfo: contextualInfo)
                }, useBingMaps: $useBingMaps, tappedCoordinate: $tappedCoordinate)
                .onChange(of: tappedCoordinate) { _ in
                    showMapLongPressedSheet = tappedCoordinate != nil
                }
                .onChange(of: viewModel.selectedQuest) { _ in
                    shouldShowPolyline = false
                }
                .id(viewModel.refreshMap)
                .edgesIgnoringSafeArea(.all)
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                   ActivityView(activityText: "Looking for quests...")
                }
                if showAlert {
                    VStack {
                        Image(systemName: alertIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .foregroundColor(.green)
                            .padding(.bottom, 50)
                        Text(alertMessage)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(10)
                    }
                    .padding([.all], 50)
                    .background(Color.white)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(alertMessage)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            showAlert = false // Dismiss notification box after 1 second
                        }
                    }
                }
                
              
                FloatingActionButtonStack(mapButtonAction: {
                    useBingMaps.toggle()
                }, useBingMaps: useBingMaps)
                   
            }
            .environmentObject(contextualInfo)
            .navigationBarHidden(isPresented)
            .navigationBarItems(leading: EmptyView())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: UserProfileView()) {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundStyle(Color(red: 135/255, green: 62/255, blue: 242/255))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("Refresh icon tapped")
                        viewModel.fetchOSMDataFor(currentLocation: viewModel.userlocation)
                    }) {
                        Image(systemName: "arrow.2.circlepath")
                            .frame(width: 20, height: 20)
                            .foregroundStyle(Color(red: 135/255, green: 62/255, blue: 242/255))
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSyncing {
                        ProgressView()
                    }else{
                        EmptyView()
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .onChange(of: showPopover) { newValue in
                if !newValue {
                    shouldShowPolyline = false
                }
            }
            .onChange(of: isPresented) { newValue in
                if !newValue {
                    shouldShowPolyline = false
                }
            }
            .sheet(isPresented: $showMapLongPressedSheet) {
                if let _ = tappedCoordinate {
                    VStack(spacing: 12) {
                        Button(action: {
                            showMapLongPressedSheet = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                 showCreateNoteSheet = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "note.text.badge.plus")
                                Text("Create Note")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(12)
                        }
                        .foregroundColor(.blue)

                        Button(action: {
                            showMapLongPressedSheet = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showAddFeatureSheet = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "plus.viewfinder")
                                Text("Add Feature")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(12)
                        }
                        .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 5)
                    .presentationDetents([.fraction(0.2)])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showCreateNoteSheet, content: {
                CreateNoteView(coordinates: tappedCoordinate ?? CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), showNotesBox: $showCreateNoteSheet, dismissSheet: { message in
                    if message.contains("error") {
                        alertIcon = "exclamationmark.triangle.fill"
                    } else {
                        alertIcon = "checkmark.circle.fill"
                    }
                    alertMessage = message
                    showAlert = true
                    
                })
                    .presentationDetents([.fraction(0.6)])
                    .presentationDragIndicator(.visible)
                
            })
            .sheet(isPresented: $showAddFeatureSheet) {
                AddFeatureView(tappedCoordinate: tappedCoordinate ?? CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), isPresented: $showAddFeatureSheet, dismissSheet: { message in
                    if message.contains("wrong") {
                        alertIcon = "exclamationmark.triangle.fill"
                    } else {
                        alertIcon = "checkmark.circle.fill"
                    }
                    alertMessage = message
                    showAlert = true
                })
                    .presentationDetents([.fraction(0.6)])
                    .presentationDragIndicator(.visible)
            }

        .sheet(isPresented: $isPresented, content: {
            let selectedQuest = self.viewModel.selectedQuest
            CustomSheetView {
                selectedQuest?.parent?.form
            }
            .onAppear {
                shouldShowPolyline = true
            }
            .presentationDetents([.fraction(0.8), .fraction(0.5), .fraction(0.1)], selection: $selectedDetent)
            .presentationDragIndicator(.visible)
            .scrollDisabled(false)
            .interactiveDismissDisabled()
            .environmentObject(contextualInfo)
           
        })
        .onReceive(MapViewPublisher.shared.dismissSheet) { scenario in
            
            isPresented = false
            switch scenario {
            case .dismissed:
                shouldShowPolyline = false
            case .submitted(let elementId):
                shouldShowPolyline = false
                showAlert = true
                alertMessage = "Quest Submitted"
                viewModel.refreshMapAfterSubmission(elementId: elementId)
            case .syncing:
                isSyncing = true
                print("syncing")
            case .synced:
                isSyncing = false
                print("synced")
                alertIcon = "checkmark.circle.fill"
            case .hideElement(let elementId):
                shouldShowPolyline = false
                viewModel.hideQuest(elementId: elementId)
            }
        }
        .onReceive(QuestsPublisher.shared.refreshQuest, perform: { _ in
            viewModel.refreshQuests()
        })
        .onAppear(){
            print("selected workspace",selectedWorkspace?.title ?? "")
            QuestsRepository.shared.loadLongQuests(from: "longQuestJson")
            self.baseUrl = "https://osm.workspaces-stage.sidewalks.washington.edu"
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

public class QuestsPublisher: ObservableObject {
    public let refreshQuest = PassthroughSubject<String, Never>()
    static let shared = QuestsPublisher()
    private init() {}
}

public enum SheetDismissalScenario {
    case dismissed
    case submitted(String)
    case syncing
    case synced
    case hideElement(String)
}

//TODO: Move to a new file
class ContextualInfo: ObservableObject {
    static let shared = ContextualInfo()
    
    @Published var info: String = "Contextual info appears here"
    
    private init() {}
}


struct CustomSheetView<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        CustomSheetWrapper(content: content)
            .ignoresSafeArea() // To handle full screen if needed
    }
}

struct CustomSheetWrapper<Content: View>: UIViewControllerRepresentable {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let hostingController = UIHostingController(rootView: content())
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        viewController.view.addSubview(hostingController.view)

        // Pin the content to all edges
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor)
        ])

        viewController.view.backgroundColor = .clear
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }

    // Add custom UISheetPresentationController configuration
    static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: ()) {
        if let sheet = uiViewController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
    }
}
