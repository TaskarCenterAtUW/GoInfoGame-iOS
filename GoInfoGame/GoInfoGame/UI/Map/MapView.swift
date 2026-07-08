//
//  MapView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 23/01/24.
//

import SwiftUI
import MapKit       // For MapUserTrackingMode
import MapLibre
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
    @State private var lineCoordinates: [CLLocationCoordinate2D] = []
    @State private var isSyncing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertIcon = ""
    @StateObject var contextualInfo = ContextualInfo.shared

    @State private var selectedDetent: PresentationDetent = .fraction(0.8)
    @State private var showPopover = false

    @AppStorage("baseUrl") var baseUrl = ""

    @State private var tappedCoordinate: CLLocationCoordinate2D? = nil
    @State private var annotationCoordinate: CLLocationCoordinate2D? = nil
    @State private var showMapLongPressedSheet = false
    @State private var showAddFeatureSheet = false
    @State private var showCreateNoteSheet = false
    @State private var showUserSettingsSheet = false
    @State private var enableAccessibility = false
    @State private var showMultiSelectionBottomSheet = false

    @State private var mapViewRef: MLNMapView?

    @State private var navigateToProfile = false
    @State private var showManageQuestSheet = false
    @State private var showZoomInAlert = false
    @State private var shadowRegions: [CoordinateBounds] = []
    @State private var showUndoSidebar = false
    @State private var showFilterQuestsSheet = false
    @State private var showElemntDeletedAlert = false
    @State private var activeConflict: PendingSyncConflict?

    var body: some View {
        NavigationStack {
            ZStack {
                NavigationLink(
                    destination: UserProfileView(),
                    isActive: $navigateToProfile
                ) { EmptyView() }

                CustomMap(
                    centerCoordinate: $viewModel.centerCoordinate,
                    trackingMode: $trackingMode,
                    items: $viewModel.items,
                    selectedQuest: $viewModel.selectedQuest,
                    shouldShowPolyline: $shouldShowPolyline,
                    isPresented: $isPresented,
                    isUserSettingsPresented: $showUserSettingsSheet,
                    selectedAnnotations: $viewModel.selectedAnnotaions,
                    isMultiSelectModeEnabled: $viewModel.isMultiSelectModeEnabled,
                    selectedAnnotationType: $viewModel.selectedAnnotationType,
                    showMultiSelectionBottomSheet: $showMultiSelectionBottomSheet,
                    selectedSatelliteOption: $viewModel.selectedOption,
                    lineCoordinates: $lineCoordinates,
                    onMapViewCreated: { map in
                        self.mapViewRef = map
                    },
                    contextualInfo: { info in
                        selectedDetent = .fraction(0.8)
                        setContextualInfo(contextualinfo: info)
                    },
                    tappedCoordinate: $tappedCoordinate,
                    annotationCoordinate: $annotationCoordinate,
                    shadowRegions: $shadowRegions
                )
                .accessibilityHidden(enableAccessibility)
                .onChange(of: tappedCoordinate) { _ in
                    showMapLongPressedSheet = tappedCoordinate != nil
                }
                .onChange(of: viewModel.selectedQuest) { _ in
                    shouldShowPolyline = false
                }
                .id(viewModel.refreshMap)
                .edgesIgnoringSafeArea(.all)

                if viewModel.isLoading {
                    Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
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
                            .frame(maxWidth: .infinity)
                            .background(Asset.Colors.huskyPurple.swiftUIColor)
                            .cornerRadius(12)
                    }
                    .padding(24)
                    .frame(maxWidth: 350)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(alertMessage)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showAlert = false }
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading) {
                            UndoButton(
                                onPreview: { _, _ in },
                                onRemovePreview: {},
                                onRevert: { id in MapUndoManager.shared.undo(for: id) }
                            )
                            .accessibilitySortPriority(1)

                            if case .wmts(let server) = viewModel.selectedOption,
                               server.attribution.attributionRequired,
                               let url = URL(string: server.attribution.url),
                               UIApplication.shared.canOpenURL(url) {
                                Button(action: { UIApplication.shared.open(url) }) {
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

                        VStack(alignment: .trailing, spacing: 10) {
                            Spacer()

                            // Zoom out
                            FloatingActionButton(systemName: "minus.magnifyingglass") {
                                if let mapView = mapViewRef {
                                    let newZoom = max(mapView.zoomLevel - 1.0, 0)
                                    mapView.setZoomLevel(newZoom, animated: true)
                                    voiceOverAnnounce(message: "Zoomed out to level \(Int(newZoom))")
                                }
                            }
                            .accessibilityLabel(L10n.Localizable.zoomOutMap)
                            .accessibilitySortPriority(1)

                            // Zoom in
                            FloatingActionButton(systemName: "plus.magnifyingglass") {
                                if let mapView = mapViewRef {
                                    let newZoom = min(mapView.zoomLevel + 1.0, 22)
                                    mapView.setZoomLevel(newZoom, animated: true)
                                    voiceOverAnnounce(message: "Zoomed in to level \(Int(newZoom))")
                                }
                            }
                            .accessibilityLabel(L10n.Localizable.zoomInMap)
                            .accessibilitySortPriority(1)

                            // Filter quests
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
                        }
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
                            viewModel.isMultiSelectModeEnabled = false
                            viewModel.selectedAnnotaions = Set<DisplayUnitAnnotation>()
                        },
                        onAnswerQuests: { isPresented = true }
                    )
                    .transition(.move(edge: .bottom))
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
                HStack(spacing: 10) {
                    Button(action: { navigateToProfile = true }) {
                        Image(systemName: "person.fill")
                            .padding(8)
                            .foregroundStyle(Color.white)
                            .background {
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Asset.Colors._8F57DEProfileIcon.swiftUIColor,
                                        Asset.Colors._2D0369ProfileIcon.swiftUIColor
                                    ]),
                                    startPoint: .top, endPoint: .bottom
                                )
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
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading) {
                                Text(L10n.Localizable.workspace)
                                    .font(FontFamily.Lato.regular.swiftUIFont(size: 12, relativeTo: .body))
                                    .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                                    .multilineTextAlignment(.leading)
                                Text(selectedWorkspace.title)
                                    .font(FontFamily.Lato.bold.swiftUIFont(size: 14, relativeTo: .body))
                                    .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(L10n.Localizable.workspace): \(selectedWorkspace.title)")
                    }
                }
            }
            ToolbarItem(placement: .topBarLeading) { }

            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 5.0) {
                    accessbilityButton

                    QuestSyncButton(
                        badgeCount: viewModel.syncFailedElementsCount,
                        isSyncing: isSyncing,
                        action: {
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
                        }
                    )

                    Button(action: {
                        viewModel.updateOptions(
                            for: mapViewRef?.centerCoordinate
                                ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
                        )
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

                    Button(action: { showUserSettingsSheet = true }) {
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
            if !newValue { shouldShowPolyline = false }
        }
        .onChange(of: isPresented) { newValue in
            if !newValue { shouldShowPolyline = false }
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
                        mapViewRef?.maximumZoomLevel = Double(wmts.extent.maxZoom)
                    } else {
                        mapViewRef?.maximumZoomLevel = 22
                    }
                    viewModel.showSatellitePicker = false
                }
            )
            .background(Color(red: 248/255, green: 248/255, blue: 248/255))
            .presentationDetents([.fraction(0.36)])
            .presentationDragIndicator(.visible)
            .applyPresentationSizingPage()
        }
        .sheet(isPresented: $showUserSettingsSheet) {
            UserSettingsView(
                selectedWorkspace: selectedWorkspace.title,
                options: OptionModel.options,
                onNavigate: { navigate in
                    showUserSettingsSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        switch navigate {
                        case .profile:
                            navigateToProfile = true

                        case .manageQuests:
                            showManageQuestSheet = true

                        case .downloadData:
                            guard let mapView = mapViewRef else { return }
                            let bbox = viewModel.boundingBoxFromVisibleMapRect(mapView: mapView)
                            if !isBBoxValid(bbox) {
                                showZoomInAlert = true
                                return
                            }
                            viewModel.fetchOSMDataFor(from: .visibleRect(mapView: mapView))

                            // Expand the visible bounds slightly and add as a shadow cutout
                            let bounds = mapView.visibleCoordinateBounds
                            let latPad = (bounds.ne.latitude  - bounds.sw.latitude)  * 0.25
                            let lonPad = (bounds.ne.longitude - bounds.sw.longitude) * 0.25
                            shadowRegions.append(CoordinateBounds(
                                sw: CLLocationCoordinate2D(
                                    latitude:  bounds.sw.latitude  - latPad,
                                    longitude: bounds.sw.longitude - lonPad
                                ),
                                ne: CLLocationCoordinate2D(
                                    latitude:  bounds.ne.latitude  + latPad,
                                    longitude: bounds.ne.longitude + lonPad
                                )
                            ))

                        case .switchWorkspace:
                            switchToInitialView()
                        }
                    }
                }
            )
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
                            Text("Create Note").fontWeight(.semibold)
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
                            Text("Add Feature").fontWeight(.semibold)
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
        .sheet(isPresented: $showCreateNoteSheet) {
            CreateNoteView(
                coordinates: tappedCoordinate ?? CLLocationCoordinate2D(),
                showNotesBox: $showCreateNoteSheet,
                dismissSheet: { message in
                    alertIcon = message.contains("Error")
                        ? "exclamationmark.triangle.fill"
                        : "checkmark.circle.fill"
                    alertMessage = message
                    showAlert = true
                }
            )
            .presentationDetents([.fraction(0.6)])
            .presentationDragIndicator(.visible)
            .applyPresentationSizingPage()
        }
        .sheet(isPresented: $showAddFeatureSheet) {
            AddFeatureView(
                tappedCoordinate: tappedCoordinate ?? CLLocationCoordinate2D(),
                isPresented: $showAddFeatureSheet,
                dismissSheet: { message in
                    alertIcon = message.contains("wrong")
                        ? "exclamationmark.triangle.fill"
                        : "checkmark.circle.fill"
                    alertMessage = message
                    showAlert = true
                }
            )
            .presentationDetents([.fraction(0.6)])
            .presentationDragIndicator(.visible)
            .applyPresentationSizingPage()
        }
        .sheet(isPresented: $isPresented) {
            QuestSheetView(viewModel: viewModel, annotationCoordinate: annotationCoordinate)
                .onAppear { shouldShowPolyline = true }
                .presentationDetents([.fraction(0.8), .fraction(0.5), .fraction(0.1)],
                                     selection: $selectedDetent)
                .presentationDragIndicator(.visible)
                .scrollDisabled(false)
                .interactiveDismissDisabled()
                .environmentObject(contextualInfo)
                .applyPresentationSizingPage()
        }
        .onReceive(MapViewPublisher.shared.dismissSheet) { scenario in
            isPresented = false
            switch scenario {
            case .dismissed:
                shouldShowPolyline = false
            case .syncing:
                isSyncing = true
            case .synced:
                isSyncing = false
                viewModel.checkSyncStatus()
            case .failed:
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
        .onReceive(QuestsPublisher.shared.refreshQuest) { _ in
            viewModel.refreshQuests()
        }
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
        .onReceive(MapViewPublisher.shared.conflictDetected) { conflict in
            activeConflict = conflict
        }
        .sheet(item: $activeConflict) { conflict in
            ConflictResolutionSheet(conflict: conflict)
                .interactiveDismissDisabled()
                .applyPresentationSizingPage()
        }
        .onAppear {
            HiddenQuestManager.shared.loadHiddenQuests()
            QuestsRepository.shared.loadLongQuests(from: "longQuestJson")
        }
    }

    // MARK: – Helpers

    func voiceOverAnnounce(message: String) {
        guard isVoiceOverOn else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if #available(iOS 17.0, *) {
                AccessibilityNotification.Announcement(message).post()
            } else {
                UIAccessibility.post(notification: .announcement, argument: message)
            }
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
        isBBoxValid(minLat: bbox.minLat, minLon: bbox.minLon, maxLat: bbox.maxLat, maxLon: bbox.maxLon)
    }

    private func isBBoxValid(minLat: Double, minLon: Double, maxLat: Double, maxLon: Double) -> Bool {
        let latDistanceKm = haversineDistance(lat1: minLat, lon1: minLon, lat2: maxLat, lon2: minLon)
        let lonDistanceKm = haversineDistance(lat1: minLat, lon1: minLon, lat2: minLat, lon2: maxLon)
        return latDistanceKm * lonDistanceKm < 3.0
    }

    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let r = 6371.0
        let dLat = degreesToRadians(lat2 - lat1)
        let dLon = degreesToRadians(lon2 - lon1)
        let a = sin(dLat/2)*sin(dLat/2) +
            cos(degreesToRadians(lat1))*cos(degreesToRadians(lat2))*sin(dLon/2)*sin(dLon/2)
        return r * 2 * atan2(sqrt(a), sqrt(1 - a))
    }

    private func degreesToRadians(_ d: Double) -> Double { d * .pi / 180.0 }

    private var accessbilityButton: some View {
        Button(action: { enableAccessibility = true }) {
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

// MARK: – Supporting views (unchanged)

struct QuestSheetView: View {
    @ObservedObject var viewModel: MapViewModel
    let annotationCoordinate: CLLocationCoordinate2D?
    @Environment(\.dismiss) var dismiss

    @State private var isCheckingFreshness = true
    @State private var alreadyCompletedMessage: String?

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
            if isCheckingFreshness {
                ProgressView("Checking for updates...")
            } else if let message = alreadyCompletedMessage {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.green)
                    Text(message)
                        .multilineTextAlignment(.center)
                    Button(action: { dismiss() }) {
                        Text("OK")
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 32)
                            .background(Asset.Colors.huskyPurple.swiftUIColor)
                            .cornerRadius(12)
                    }
                }
                .padding(24)
            } else if let selectedQuest = viewModel.getSelectedQuest() {
                CustomSheetView { selectedQuest.parent?.form }
            } else {
                EmptyView()
            }
        }
        .task(id: viewModel.selectedQuest?.id) {
            guard !viewModel.isMultiSelectModeEnabled,
                  let longQuest = viewModel.getSelectedQuest()?.parent as? LongElementQuest else {
                isCheckingFreshness = false
                return
            }
            if let latestTags = await longQuest.fetchLatestTagsIfNeeded(),
               latestTags["ext:gig_complete"] == "yes" {
                alreadyCompletedMessage = "This element has already been answered by another user."
                viewModel.refreshQuests()
            }
            isCheckingFreshness = false
        }
        .onReceive(MapViewPublisher.shared.dismissSheet) { _ in dismiss() }
    }
}

public struct ConflictingTag: Identifiable {
    public let id = UUID()
    let key: String
    let existingValue: String
    let answeredValue: String
}

public enum TagResolutionChoice {
    case useMine
    case useServer
}

public enum ConflictResolutionDecision {
    case cancelled
    case resolved([String: TagResolutionChoice])
}

public struct PendingSyncConflict: Identifiable {
    public let id = UUID()
    let elementId: Int64
    let elementTypeName: String
    let iconName: String
    let conflicts: [ConflictingTag]
    let resolve: (ConflictResolutionDecision) -> Void
}

struct ConflictResolutionSheet: View {
    let conflict: PendingSyncConflict
    @Environment(\.dismiss) private var dismiss
    @State private var choices: [String: TagResolutionChoice]

    init(conflict: PendingSyncConflict) {
        self.conflict = conflict
        _choices = State(initialValue: Dictionary(
            uniqueKeysWithValues: conflict.conflicts.map { ($0.key, .useMine) }
        ))
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(spacing: 12) {
                        Image(uiImage: UIImage(named: conflict.iconName) ?? UIImage(systemName: "mappin.circle")!)
                            .resizable()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(conflict.elementTypeName)
                                .font(.headline)
                            Text("ID: \(String(conflict.elementId))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Text("This element was changed by someone else while you were answering. Choose which value to keep for each tag below.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                ForEach(conflict.conflicts) { tag in
                    Section {
                        Picker(tag.key, selection: Binding(
                            get: { choices[tag.key] ?? .useMine },
                            set: { choices[tag.key] = $0 }
                        )) {
                            (Text("Your answer: ")
                                .foregroundColor(Asset.Colors.a2A2A2Gray.swiftUIColor)
                             + Text(tag.answeredValue)
                                .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                                .fontWeight(.semibold))
                                .tag(TagResolutionChoice.useMine)
                            (Text("Existing value: ")
                                .foregroundColor(Asset.Colors.a2A2A2Gray.swiftUIColor)
                             + Text(tag.existingValue)
                                .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                                .fontWeight(.semibold))
                                .tag(TagResolutionChoice.useServer)
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    } header: {
                        Text(questionText(forTagKey: tag.key))
                            .fontWeight(.semibold)
                            .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Resolve Conflicts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        conflict.resolve(.cancelled)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        conflict.resolve(.resolved(choices))
                        dismiss()
                    }
                    .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                }
            }
        }
    }

    private func questionText(forTagKey key: String) -> String {
        let quest = QuestsRepository.shared.longQuestModels
            .first(where: { $0.elementType.lowercased() == conflict.elementTypeName.lowercased() })?
            .quests.first(where: { $0.questTag == key })
        return quest?.questTitle ?? key
    }
}

public class MapViewPublisher: ObservableObject {
    public let dismissSheet = PassthroughSubject<SheetDismissalScenario, Never>()
    public let conflictDetected = PassthroughSubject<PendingSyncConflict, Never>()
    static let shared = MapViewPublisher()
    private init() {}
}

public class QuestsPublisher: ObservableObject {
    public let refreshQuest    = PassthroughSubject<String, Never>()
    public let elementDeleted  = PassthroughSubject<Int, Never>()
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

class ContextualInfo: ObservableObject {
    static let shared = ContextualInfo()
    @Published var info: String = "Contextual info appears here"
    private init() {}
}

struct CustomSheetView<Content: View>: View {
    let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    var body: some View {
        CustomSheetWrapper(content: content).ignoresSafeArea()
    }
}

struct CustomSheetWrapper<Content: View>: UIViewControllerRepresentable {
    let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        let hc = UIHostingController(rootView: content())
        hc.view.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(hc.view)
        NSLayoutConstraint.activate([
            hc.view.topAnchor.constraint(equalTo: vc.view.topAnchor),
            hc.view.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor),
            hc.view.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor)
        ])
        vc.view.backgroundColor = .clear
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

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
        VStack {
            HStack {
                Image(uiImage: selectedAnnotationImage)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.gray)
                Text("**Select \(selectedAnnotationType):**").font(.headline)
                Text("\(selectedCount) \(selectedAnnotationType.lowercased()) selected")
                    .font(.subheadline).foregroundColor(.gray)
                Spacer()
            }
            .padding()

            VStack {
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
            .cornerRadius(20)
            .padding()
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 5)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}

#Preview {
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
}
