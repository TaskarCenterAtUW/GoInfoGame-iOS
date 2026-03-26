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
    let selectedWorkspace: Workspace
    @State var trackingMode: MapUserTrackingMode = MapUserTrackingMode.follow
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.accessibilityVoiceOverEnabled) var isVoiceOverOn
    @AppStorage("isMapFromOnboarding") var isMapFromOnboarding: Bool = false
    @StateObject var viewModel: MapViewModel
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
    
    @State private var showSattiliteSelectionSheet: Bool = false
    
    @State private var tappedCoordinate: CLLocationCoordinate2D? = nil
    
    @State private var annotationCoordinate: CLLocationCoordinate2D? = nil
    
    @State private var showMapLongPressedSheet = false
    
    @State private var showAddFeatureSheet = false
    
    @State private var showCreateNoteSheet = false
    
    @State private var showUserSettingsSheet = false
    
    @State private var enableAccessibility = false
    
    @State private var showMultiSelectionBottomSheet = false
    
    @State private var mapViewRef: MKMapView?
    
    @State private var navigateToProfile = false
    
    @State private var showManageQuestSheet = false
    
    @State private var showZoomInAlert = false
    
    @State private var shadowOverlay = ShadowOverlay()
    
    @State private var showUndoSidebar = false
    @State private var shatilliteSelected: String? = nil
    @State private var showFilterQuestsSheet = false
    @State private var showElemntDeletedAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                NavigationLink(
                    destination: UserProfileView(),
                    isActive: $navigateToProfile
                ) {
                    EmptyView() // Empty view as it's handled by isActive binding
                }
                
                
                CustomMap(region: $viewModel.region,
                          trackingMode: $trackingMode,
                          items: $viewModel.items,
                          selectedQuest: $viewModel.selectedQuest,
                          shouldShowPolyline: $shouldShowPolyline,
                          
                          isPresented: $isPresented,
                          isUserSettingsPresented: $showUserSettingsSheet,
                          selectedAnnotations: $viewModel.selectedAnnotaions,
                          isMultiSelectModeEnabled: $viewModel.isMultiSelectModeEnabled,
                          selectedAnnotationType: $viewModel.selectedAnnotationType,
                          showMultiSelectionBottomSheet: $showMultiSelectionBottomSheet ,
                          selectedSattiliteOption: $viewModel.selectedOption,
                          onMapViewCreated: { map in
                    self.mapViewRef = map
                } ,
                          contextualInfo: { contextualInfo in
                    print(contextualInfo)
                    selectedDetent = .fraction(0.8)
                    self.setContextualInfo(contextualinfo: contextualInfo)
                },
                          tappedCoordinate: $tappedCoordinate,
                          annotationCoordinate: $annotationCoordinate,
                          shadowOverlay: shadowOverlay)
                .accessibilityHidden(enableAccessibility) // Hide map from VoiceOver when accessibility mode is enabled
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
                    VStack(spacing: 20) {
                        Image(systemName: alertIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(Asset.Colors.accentPink.swiftUIColor)
                        
                        Text(alertMessage)
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity) // stretch text inside fixed card
                            .background(Asset.Colors.huskyPurple.swiftUIColor)
                            .cornerRadius(12)
                    }
                    .padding(24)
                    .frame(maxWidth: 350) // increased card width
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(alertMessage)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showAlert = false
                        }
                    }
                }
                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading) {
                            UndoButton(
                                onPreview: { id, type in
                                },
                                onRemovePreview: {
                                },
                                onRevert: { id in
                                    MapUndoManager.shared.undo(for: id)
                                }
                            )
                            .accessibilitySortPriority(1)
                            if case .wmts(let server) = viewModel.selectedOption,
                               server.attribution.attributionRequired,
                               let url = URL(string: server.attribution.url),
                               UIApplication.shared.canOpenURL(url) {
                                Button(action: {
                                    UIApplication.shared.open(url)
                                }) {
                                    Text(server.attribution.text)
                                        .background(.white.opacity(0.6))
                                        .foregroundColor(.black)
                                        .padding()
                                        .font(.system(size: 8, weight: .light))
                                        .cornerRadius(8)
                                }
                            }
                            
                        }
                        .padding(.bottom, 24)
                        .padding(.leading, 16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 10, content: {
                            Spacer()
                            FloatingActionButton(systemName: "minus.magnifyingglass") {
                                if var region = mapViewRef?.region {
                                    region.span.latitudeDelta *= 2.0
                                    region.span.longitudeDelta *= 2.0
                                    if region.span.latitudeDelta < 170.0 && region.span.longitudeDelta < 350.0 {
                                        mapViewRef?.setRegion(region, animated: true)
                                        if let newZoom = mapViewRef?.zoomLevelFor(longitudeDelta: region.span.longitudeDelta) {
                                            voiceOverAnnounce(message: "Zoomed out to level \(newZoom)")
                                        }
                                    }
                                }
                            }
                            .accessibilityLabel(L10n.Localizable.zoomOutMap)
                            .accessibilitySortPriority(1)
                            
                            FloatingActionButton(systemName: "plus.magnifyingglass") {
                                if var region = mapViewRef?.region {
                                    region.span.latitudeDelta *= 0.5
                                    region.span.longitudeDelta *= 0.5
                                    mapViewRef?.setRegion(region, animated: true)
                                    if let newZoom = mapViewRef?.zoomLevelFor(longitudeDelta: region.span.longitudeDelta) {
                                        voiceOverAnnounce(message: "Zoomed in to level \(newZoom)")
                                    }
                                }
                            }
                            .accessibilityLabel(L10n.Localizable.zoomInMap)
                            .accessibilitySortPriority(1)
                            
                            FloatingActionButton(systemName: "slider.horizontal.3") {
                                showFilterQuestsSheet.toggle()
                            }
                            .accessibilityLabel(L10n.Localizable.filterQuestTypes)
                            .accessibilitySortPriority(1)
                            .sheet(isPresented: $showFilterQuestsSheet) {
                                ManageQuestsView()
                                    .presentationDetents([.fraction(0.85)])
                                    .interactiveDismissDisabled()
                                    .presentationDragIndicator(.hidden)
                                    .applyPresentationSizingPage()
                                    .focusAccessibilityOnAppear()
                            }
                        })
                        .padding(.bottom, 24)
                        .padding(.trailing, 16)
                        .frame(alignment: .bottomLeading)
                    }
                }
                
                if !viewModel.selectedAnnotaions.isEmpty,
                   let selectedAnnotationType = viewModel.selectedAnnotationType,
                   let image = UIImage(named: viewModel.selectedAnnotaions.first?.displayUnit?.parent?.iconName ?? "notes") {
                    
                    MultiQuestSelectionBottomSheet(
                        selectedAnnotationType: selectedAnnotationType,
                        selectedAnnotationImage: image,
                        selectedCount: viewModel.selectedAnnotaions.count,
                        onCancel: {
                            viewModel.selectedAnnotaions.removeAll()
                            viewModel.selectedAnnotationType = nil
                            //                        DispatchQueue.main.async {
                            viewModel.isMultiSelectModeEnabled = false
                            viewModel.selectedAnnotaions = Set<DisplayUnitAnnotation>()
                            //                        }
                        },
                        onAnswerQuests: {
                            isPresented = true
                        }
                    )
                    .transition(.move(edge: .bottom)) // Smooth animation
                    .animation(.easeInOut, value: viewModel.selectedAnnotaions.count)
                }
            }
            .alert("Zoom in to download data", isPresented: $showZoomInAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The map area is too large. Please zoom in and try again.")
            }
        }
        .environmentObject(contextualInfo)
        .navigationBarHidden(isPresented)
        .navigationBarItems(leading: EmptyView())
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 10)  {
                    Button(action: {
                        navigateToProfile = true
                    }) {
                        Image(systemName: "person.fill")
                            .padding(8)
                            .foregroundStyle(Color.white)
                            .background {
                                LinearGradient(gradient: Gradient(colors: [Asset.Colors._8F57DEProfileIcon.swiftUIColor, Asset.Colors._2D0369ProfileIcon.swiftUIColor,]), startPoint: .top, endPoint: .bottom)
                            }
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                            .accessibilityLabel(L10n.Localizable.profile)
                    }
                    
                    Rectangle()
                        .fill(Asset.Colors.ddddddLine.swiftUIColor)
                        .frame(width: 1, height: 24)
                        .cornerRadius(0.5)
                    
                    VStack(alignment: .leading) {
                        Text(L10n.Localizable.workspace)
                            .font(FontFamily.Lato.regular.swiftUIFont(size: 12))
                            .foregroundStyle(Asset.Colors._83879BTextFiledTitle.swiftUIColor)
                        
                        Text(selectedWorkspace.title)
                            .font(FontFamily.Lato.bold.swiftUIFont(size: 14))
                            .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                    }
                }
                
            }
            ToolbarItem(placement: .topBarLeading) {
                
                
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 5.0) {
                    accessbilityButton
                    QuestSyncButton(badgeCount: viewModel.syncFailedElementsCount, isSyncing: isSyncing, action: {
                        debugPrint("Sync taped")
                        guard viewModel.syncFailedElementsCount > 0 else {
                            alertIcon = "info.bubble"
                            alertMessage = "No elements to sync"
                            showAlert = true
                            return
                        }
                        isSyncing = true
                        DatasyncManager.shared.syncDataToOSM(exclude_gig_tags: false) { _ in
                            isSyncing = false
                            viewModel.checkSyncStatus()
                        }
                    })
                    
                    Button(action: {
                        debugPrint("satellite icon tapped")
                        viewModel.updateOptions(for: mapViewRef?.region.center ?? CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0))
                        viewModel.showSatellitePicker = true
                    }) {
                        Image(systemName: "square.2.layers.3d.bottom.filled")
                            .resizable()
                            .padding(8)
                            .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                            .background(Asset.Colors.e7E3EELightPurpuleBg.swiftUIColor)
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                            .accessibilityLabel(L10n.Localizable.mapModes)
                    }
                    
                    Button(action: {
                        print("Settings icon tapped")
                        showUserSettingsSheet = true
                    }) {
                        Image(systemName: "gear")
                            .resizable()
                            .padding(8)
                            .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                            .background(Asset.Colors.e7E3EELightPurpuleBg.swiftUIColor)
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                    }
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
        
        .sheet(isPresented: $showManageQuestSheet) {
            ManageQuestsView()
                .presentationDetents([.fraction(0.85)])
                .interactiveDismissDisabled()
                .presentationDragIndicator(.hidden)
                .applyPresentationSizingPage()
                .focusAccessibilityOnAppear()
        }
        .sheet(isPresented: $viewModel.showSatellitePicker) {
            SatellitePickerSheet(
                options: $viewModel.availableOptions,
                selected: $viewModel.selectedOption,
                onSelect: { selected in
                    viewModel.selectedOption = selected
                    if case .wmts(let wmts) = selected {
                        mapViewRef?.setCameraZoomRange(MKMapView.CameraZoomRange(minCenterCoordinateDistance: mapViewRef?.distanceForZoom(zoomLevel: wmts.extent.maxZoom) ?? 0.0), animated: true)
                    } else {
                        mapViewRef?.setCameraZoomRange(nil, animated: true)
                    }
                    viewModel.showSatellitePicker = false
                    addOverlay(selectedSatilliteOption: selected)
                }
            )
            .background(Color(red: 248/255, green: 248/255, blue: 248/255))
            .presentationDetents([.fraction(0.36)])
            .presentationDragIndicator(.visible)
            .applyPresentationSizingPage()
        }
        .sheet(isPresented: $showUserSettingsSheet) {
            UserSettingsView(selectedWorkspace: selectedWorkspace.title, options: OptionModel.options, onNavigate: { navigate in
                showUserSettingsSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    //   navigateToProfileSettings = true
                    
                    switch navigate {
                    case .profile:
                        print("Navigate to profile")
                        // Handle navigation to profile
                        navigateToProfile = true
                        
                    case .manageQuests:
                        showManageQuestSheet = true
                        
                    case .downloadData:
                        print("Download data here")
                        
                        guard let mapView = mapViewRef else { return }
                        let bbox = viewModel.boundingBoxFromVisibleMapRect(mapView: mapView)
                        if !isBBoxValid(bbox) {
                            showZoomInAlert = true
                            return
                        }
                        viewModel.fetchOSMDataFor(from: .visibleRect(mapView: mapView))
                        let rect = mapView.visibleMapRect
                        let extendedVisibleRect = rect.insetBy(dx: -rect.size.width * 0.25, dy: -rect.size.height * 0.25)
                        shadowOverlay.addVisibleRect(extendedVisibleRect)
                        
                    case .switchWorkspace:
                        //navigate to inital view
                        print("Switch workspace here")
                        switchToInitialView()
                    }
                }
                
            })
            .background(Color(red: 248/255, green: 248/255, blue: 248/255))
            .presentationDetents([.fraction(0.38)])
            .interactiveDismissDisabled()
            .presentationDragIndicator(.hidden)
            .applyPresentationSizingPage()
            .focusAccessibilityOnAppear()
        }
        .fullScreenCover(isPresented: $enableAccessibility) {
            AccessibilityModeView(mapViewModel: viewModel)
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
                        .background(Asset.Colors.huskyPurple.swiftUIColor)
                        .cornerRadius(12)
                    }
                    .foregroundColor(.white)
                    
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
                        .background(Asset.Colors.accentPink.swiftUIColor)
                        .cornerRadius(12)
                    }
                    .foregroundColor(.white)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(radius: 5)
                .presentationDetents([.fraction(0.2)])
                .presentationDragIndicator(.visible)
                .applyPresentationSizingPage()
            }
        }
        .sheet(isPresented: $showCreateNoteSheet, content: {
            CreateNoteView(coordinates: tappedCoordinate ?? CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), showNotesBox: $showCreateNoteSheet, dismissSheet: { message in
                if message.contains("Error") {
                    alertIcon = "exclamationmark.triangle.fill"
                } else {
                    alertIcon = "checkmark.circle.fill"
                }
                alertMessage = message
                showAlert = true
                
            })
            .presentationDetents([.fraction(0.6)])
            .presentationDragIndicator(.visible)
            .applyPresentationSizingPage()
            
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
            .applyPresentationSizingPage()
        }
        
        .sheet(isPresented: $isPresented, content: {
            QuestSheetView(viewModel: viewModel, annotationCoordinate: annotationCoordinate)
                .onAppear {
                    shouldShowPolyline = true
                }
                .presentationDetents([.fraction(0.8), .fraction(0.5), .fraction(0.1)], selection: $selectedDetent)
                .presentationDragIndicator(.visible)
                .scrollDisabled(false)
                .interactiveDismissDisabled()
                .environmentObject(contextualInfo)
                .applyPresentationSizingPage()
            
        })
        .onReceive(MapViewPublisher.shared.dismissSheet) { scenario in
            
            isPresented = false
            switch scenario {
            case .dismissed:
                shouldShowPolyline = false
            case .syncing:
                isSyncing = true
                print("syncing")
            case .synced:
                isSyncing = false
                print("synced")
                viewModel.checkSyncStatus()
            case .failed(let message):
                isSyncing = false
                shouldShowPolyline = false
                viewModel.checkSyncStatus()
            case .hideElement(let elementId, let elementName):
                shouldShowPolyline = false
                viewModel.hideQuest(elementId: elementId, elementName: elementName)
            case .undoDone(let changesetId):
                shouldShowPolyline = false
                viewModel.refreshMapAfterUndoSumbit(storedChangesetId: changesetId)
            case .syncBackground(let elementID):
                shouldShowPolyline = false
                viewModel.refreshMapAfterSubmission(elementId: elementID)
            }
        }
        .onReceive(QuestsPublisher.shared.refreshQuest, perform: { _ in
            viewModel.refreshQuests()
        })
        .onReceive(
            enableAccessibility
            ? Empty<Int, Never>().eraseToAnyPublisher()
            : QuestsPublisher.shared.elementDeleted.eraseToAnyPublisher()
        ) { _ in
            showElemntDeletedAlert = true
        }
        .alert("Element is deleted from the server.", isPresented: $showElemntDeletedAlert) {
            Button("OK", role: .cancel) { }
        }
        .onAppear(){
            HiddenQuestManager.shared.loadHiddenQuests()
            print("selected workspace",selectedWorkspace.title)
            QuestsRepository.shared.loadLongQuests(from: "longQuestJson")
            //            self.baseUrl = "https://osm.workspaces-stage.sidewalks.washington.edu"
            //            let original = DatabaseConnector.shared.getNode(id: 43)
            //            let edited = DatabaseConnector.shared.getNode(id: 43)
            //            print("ORIGINAL --->>>\(original)")
            //            print("EDITED --->>>\(edited)")
        }
    }
    
    func voiceOverAnnounce(message: String) {
        guard isVoiceOverOn else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if #available(iOS 17.0, *) {
                AccessibilityNotification.Announcement(message).post()
            } else {
                UIAccessibility.post(notification: .announcement, argument: message)
            }
        }
    }
    
    func addOverlay(selectedSatilliteOption: SatelliteOption) {
        // Remove old tile overlays (keep polygons, etc. if needed)
        let oldTileOverlays = mapViewRef?.overlays.filter { $0 is WMTSSeever }
        mapViewRef?.removeOverlays(oldTileOverlays ?? [])
        switch selectedSatilliteOption {
        case .none:
            mapViewRef?.mapType = .standard
        case .wmts(let server):
            let layer = WMTSSeever(satelliteServer: server)
            mapViewRef?.addOverlay(layer, level: .aboveLabels)
        }
    }
    
    func switchToInitialView() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = UIHostingController(rootView: InitialView())
            window.makeKeyAndVisible()
        }
    }
    
    private func setContextualInfo(contextualinfo: String) {
        contextualInfo.info = contextualinfo
        
    }
    
    func isBBoxValid(_ bbox: BBox) -> Bool {
        return isBBoxValid(minLat: bbox.minLat, minLon: bbox.minLon, maxLat: bbox.maxLat, maxLon: bbox.maxLon)
    }
    
    private func isBBoxValid(minLat: Double, minLon: Double, maxLat: Double, maxLon: Double) -> Bool {
        let latDistanceKm = haversineDistance(lat1: minLat, lon1: minLon, lat2: maxLat, lon2: minLon)
        let lonDistanceKm = haversineDistance(lat1: minLat, lon1: minLon, lat2: minLat, lon2: maxLon)
        
        let areaKm2 = latDistanceKm * lonDistanceKm
        print("Area: \(areaKm2) km²")
        
        return areaKm2 < 3.0 // allow small tolerance
    }
    
    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadiusKm = 6371.0
        let dLat = degreesToRadians(lat2 - lat1)
        let dLon = degreesToRadians(lon2 - lon1)
        
        let a = sin(dLat / 2) * sin(dLat / 2) +
        cos(degreesToRadians(lat1)) * cos(degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadiusKm * c
    }
    
    private func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * .pi / 180.0
    }
    
    private var accessbilityButton: some View {
        Button(action: {
            print("Accessibility icon tapped")
            enableAccessibility = true
        }) {
            Image("accessibility")
                .resizable()
                .padding(8)
                .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                .background(Asset.Colors.e7E3EELightPurpuleBg.swiftUIColor)
                .aspectRatio(1.0, contentMode: .fit)
                .frame(width: 34, height: 34)
                .clipShape(Circle())
        }
        .accessibilityLabel(L10n.Localizable.screenReaderMode)
    }
}

struct QuestSheetView: View {
    @ObservedObject var viewModel: MapViewModel
    let annotationCoordinate: CLLocationCoordinate2D?
    @Environment(\.dismiss) var dismiss
    
    init(viewModel: MapViewModel, annotationCoordinate: CLLocationCoordinate2D?) {
        self.viewModel = viewModel
        self.annotationCoordinate = annotationCoordinate
        
        if let quest = viewModel.getSelectedQuest(),
           let longQuest = quest.parent as? LongElementQuest {
            longQuest.annotationCoordinate = annotationCoordinate
        }
    }
    
    var body: some View {
        Group {
            if let selectedQuest = viewModel.getSelectedQuest() {
                CustomSheetView {
                    selectedQuest.parent?.form
                }
            } else {
                EmptyView()
            }
        }
        .onReceive(MapViewPublisher.shared.dismissSheet) { _ in
            dismiss()
        }
    }
}

public class MapViewPublisher: ObservableObject {
    public let dismissSheet = PassthroughSubject<SheetDismissalScenario, Never>()
    static let shared = MapViewPublisher()
    private init() {}
}

public class QuestsPublisher: ObservableObject {
    public let refreshQuest = PassthroughSubject<String, Never>()
    public let elementDeleted = PassthroughSubject<Int, Never>()
    static let shared = QuestsPublisher()
    private init() {}
}

public enum SheetDismissalScenario {
    case dismissed
    case syncing
    case synced
    case failed(String)
    case hideElement(String, String)
    case undoDone(String)
    case syncBackground(Int)
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

struct MultiQuestSelectionBottomSheet: View {
    var selectedAnnotationType: String
    var selectedAnnotationImage: UIImage
    var selectedCount: Int
    var onCancel: () -> Void
    var onAnswerQuests: () -> Void
    
    var body: some View {
        VStack() {
            HStack {
                Image(uiImage: selectedAnnotationImage)
                    .resizable()
                    .frame(width: 20.0, height: 20.0)
                    .foregroundColor(.gray)
                Text("**Select \(selectedAnnotationType):**")
                    .font(.headline)
                Text("\(selectedCount) \(selectedAnnotationType.lowercased()) selected")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding()
            VStack() {
                Button(action: onAnswerQuests) {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right")
                        Text("Answer Quests")
                        Spacer()
                    }
                }
                .padding()
                
                Divider()
                
                Button(action: onCancel) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Cancel")
                        Spacer()
                    }
                }
                .padding()
            }
            .background(Color.white)
            .cornerRadius(20.0)
            .padding()
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 5)
        .frame(maxHeight: .infinity, alignment: .bottom) // Ensures it stays at the bottom
    }
}

#Preview(body: {
    let jsonString = """
        {
            "id": 222,
            "type": "osw",
            "title": "Copy from stage Kondapur Dataset LF Schema 1.0.1",
            "description": null,
            "tdeiRecordId": null,
            "tdeiProjectGroupId": "1ec1c79b-6b7a-4011-936b-c75dbbd903e3",
            "tdeiServiceId": null,
            "tdeiMetadata": null,
            "createdAt": "2025-09-12T12:27:22.679848Z",
            "createdBy": "f399ba72-c9b3-4fa1-8292-b3da9000d3ad",
            "createdByName": "Srikanth Voonna",
            "externalAppAccess": 1,
            "kartaViewToken": null
          }
        """
    if let data = jsonString.data(using: .utf8),
       let workspace = try? JSONDecoder().decode(Workspace.self, from: data) {
        MapView(selectedWorkspace: workspace, viewModel: MapViewModel(workspace: workspace))
    } else {
        EmptyView()
    }
})

