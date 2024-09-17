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
    @StateObject var contextualInfo = ContextualInfo.shared
    
    @State private var selectedDetent: PresentationDetent = .fraction(0.8)
    
    @AppStorage("baseUrl") var baseUrl = ""
        
    var body: some View {
            ZStack{
                CustomMap(region: viewModel.region,
                          userLocation: viewModel.userlocation,
                          trackingMode: $trackingMode,
                          items: viewModel.items,
                          selectedQuest: $viewModel.selectedQuest,
                          shouldShowPolyline: $shouldShowPolyline,
                          
                          isPresented: $isPresented, contextualInfo: { contextualInfo in
                    print(contextualInfo)
                    self.setContextualInfo(contextualinfo: contextualInfo)
                })
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
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .foregroundColor(.green)
                            .padding(.bottom, 50)
                        Text("Quest Submitted")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(10)
                    }
                    .padding([.all], 50)
                    .background(Color.white)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Quest Submitted")
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            showAlert = false // Dismiss notification box after 1 second
                        }
                    }
                }
            }
            .environmentObject(contextualInfo)
            .navigationBarHidden(isPresented)
            .navigationBarItems(leading: EmptyView())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: UserProfileView()) {
                        Image(systemName: "person.crop.circle.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("Refresh icon tapped")
                        viewModel.fetchOSMDataFor(currentLocation: viewModel.userlocation)
                    }) {
                        Image(systemName: "arrow.2.circlepath")
                            .frame(width: 20, height: 20)
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
            CustomSheetView {
                selectedQuest?.parent?.form
            }
            .presentationDetents([.fraction(0.8), .fraction(0.5), .fraction(0.1)], selection: $selectedDetent)
            .scrollDisabled(false)
            .environmentObject(contextualInfo)
            .onAppear {
                shouldShowPolyline = true
            }
        })
        .onReceive(MapViewPublisher.shared.dismissSheet) { scenario in
            
            isPresented = false
            switch scenario {
            case .dismissed:
                shouldShowPolyline = false
            case .submitted(let elementId):
                shouldShowPolyline = false
                viewModel.refreshMapAfterSubmission(elementId: elementId)                
            case .syncing:
                isSyncing = true
                print("syncing")
            case .synced:
                isSyncing = false
                print("synced")
                showAlert = true
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
