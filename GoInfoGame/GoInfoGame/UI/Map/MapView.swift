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

/// Which follow-up flow the user picked from the pin-choice card, before the actual
/// Create Note / Add Feature sheet opens.
enum PinCreationFlow {
    case createNote
    case addFeature
}

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
    @State private var isSyncingElements = false
    @State private var isSyncingNotes = false
    @State private var isSyncingFeatures = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertIcon = ""
    @StateObject var contextualInfo = ContextualInfo.shared

    @State private var selectedDetent: PresentationDetent = .fraction(0.7)
    @State private var showPopover = false

    @AppStorage("baseUrl") var baseUrl = ""

    @State private var tappedCoordinate: CLLocationCoordinate2D? = nil
    @State private var annotationCoordinate: CLLocationCoordinate2D? = nil
    @State private var pendingAdditionCoordinate: CLLocationCoordinate2D? = nil
    /// The small "Create Note"/"Add Feature" card anchored next to the freshly-dropped
    /// pin, shown in place of a bottom sheet. Cleared once one of the two is picked.
    @State private var showPinChoiceOverlay = false
    /// Screen-space anchor for `showPinChoiceOverlay`'s card, computed once when the
    /// pin drops. Map gestures are frozen while the card is up (see `setMapGesturesEnabled`)
    /// so the pin — and this anchor — can't drift out from under it.
    @State private var pinChoiceScreenPoint: CGPoint = .zero
    /// The coordinate actually submitted — `tappedCoordinate` as adjusted live by
    /// dragging the map underneath the fixed crosshair while Create Note/Add Feature
    /// is open. Bound directly into those views so their submit action always reads
    /// the current position, not a stale one captured at sheet-open time.
    @State private var editedCoordinate: CLLocationCoordinate2D? = nil
    /// Screen point of the fixed crosshair shown while Create Note/Add Feature is open;
    /// nil the rest of the time. See `CustomMap.Coordinator.updateEditedCoordinateIfNeeded`.
    @State private var pinEditAnchor: CGPoint? = nil
    @State private var screenSize: CGSize = .zero
    /// The feature preset picked in `AddFeatureView`'s grid, if any — drives the fixed
    /// crosshair's icon (see the `showAddFeatureSheet`/`pinEditAnchor` overlay below) so
    /// it shows what's about to be added, not just a generic pin.
    @State private var selectedFeaturePreset: FeaturePreset? = nil
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

    /// Zoom level and camera center captured right before zooming in on a selected
    /// quest, so the whole camera can be restored once the quest sheet is dismissed
    /// (cancelled or submitted) — not just the zoom.
    @State private var zoomLevelBeforeQuestSelection: Double?
    @State private var screenWidth: CGFloat = UIScreen.main.bounds.width
    @State private var centerBeforeQuestSelection: CLLocationCoordinate2D?

    /// The sync button spins whenever any queue (failed quest elements, pending
    /// notes, or pending features) is actively being drained, whichever started it.
    private var isSyncing: Bool { isSyncingElements || isSyncingNotes || isSyncingFeatures }

    /// Scales with `screenWidth` so it always leaves room for the fixed-size profile icon/divider
    /// and the 4 trailing bar buttons, without depending on navigation/transition state.
    private var workspaceTitleWidth: CGFloat {
        let leadingFixedWidth: CGFloat = 75   // spacing (20) + profile icon (34) + spacing (10) + divider (1) + spacing (10)
        let trailingFixedWidth: CGFloat = 151 // 4 icons (34 each) + 3 gaps (5 each)
        let barPadding: CGFloat = 32          // navigation bar leading/trailing padding
        let available = screenWidth - leadingFixedWidth - trailingFixedWidth - barPadding
        return min(max(available, 80), 220)
    }

    var body: some View {
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
                        selectedDetent = .fraction(0.7)
                        setContextualInfo(contextualinfo: info)
                    },
                    tappedCoordinate: $tappedCoordinate,
                    annotationCoordinate: $annotationCoordinate,
                    shadowRegions: $shadowRegions,
                    pendingAdditionCoordinate: $pendingAdditionCoordinate,
                    pinEditAnchor: $pinEditAnchor,
                    editedCoordinate: $editedCoordinate,
                    isAnySheetBlockingSelection: isAnySheetBlockingSelection,
                    dismissOtherSheets: dismissOtherSheets,
                    previousZoomLevel: $zoomLevelBeforeQuestSelection,
                    previousCenter: $centerBeforeQuestSelection,
                    ensureQuestVisibleAboveSheet: { coordinate in
                        ensureCoordinateVisibleAboveSheet(coordinate, sheetHeightFraction: Self.questSheetHeightFraction)
                    },
                    questPathEdgePadding: questPathEdgePadding
                )
                .accessibilityHidden(enableAccessibility)
                .onChange(of: tappedCoordinate) { _ in
                    guard let coordinate = tappedCoordinate else { return }
                    pendingAdditionCoordinate = coordinate
                    pinChoiceScreenPoint = pinCardAnchor(for: coordinate)
                    showPinChoiceOverlay = true
                    setMapGesturesEnabled(false)
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
                    HStack {
                        Spacer()
                        // Filter quests
                        FloatingActionButton(systemName: "slider.horizontal.3") {
                            showFilterQuestsSheet.toggle()
                        }
                        .accessibilityLabel(L10n.Localizable.filterQuestTypes)
                        .accessibilitySortPriority(1)
                        .sheet(isPresented: $showFilterQuestsSheet) {
                            ManageQuestsView()
                                // Sized to its own content by ManageQuestsView itself.
                                .interactiveDismissDisabled()
                                .presentationDragIndicator(.hidden)
                                .applyPresentationSizingPage()
                                .focusAccessibilityOnAppear()
                        }
                    }
                    .padding(.top, 24)
                    .padding(.trailing, 16)
                    .frame(alignment: .topTrailing)
                    
                    
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
                        .padding(.leading, 8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 10) {
                            Spacer()

                            // Zoom in / out — grouped pill
                            ZoomControlView(
                                onZoomIn: {
                                    if let mapView = mapViewRef {
                                        let newZoom = min(mapView.zoomLevel + 1.0, 22)
                                        mapView.setZoomLevel(newZoom, animated: true)
                                        voiceOverAnnounce(message: "Zoomed in to level \(Int(newZoom))")
                                    }
                                },
                                onZoomOut: {
                                    if let mapView = mapViewRef {
                                        let newZoom = max(mapView.zoomLevel - 1.0, 0)
                                        mapView.setZoomLevel(newZoom, animated: true)
                                        voiceOverAnnounce(message: "Zoomed out to level \(Int(newZoom))")
                                    }
                                }
                            )

                            // Current location
                            FloatingActionButton(systemName: "location.fill", iconSize: 20) {
                                if let mapView = mapViewRef,
                                   let coordinate = mapView.userLocation?.coordinate,
                                   CLLocationCoordinate2DIsValid(coordinate) {
                                    mapView.setCenter(coordinate, zoomLevel: max(mapView.zoomLevel, 15), animated: true)
                                    voiceOverAnnounce(message: "Centered on current location")
                                }
                            }
                            .accessibilityLabel(L10n.Localizable.currentLocation)
                            .accessibilitySortPriority(1)
                        }
                        .padding(.bottom, 24)
                        .padding(.trailing, 8)
                        .frame(alignment: .bottomLeading)
                    }
                }

                if !viewModel.selectedAnnotaions.isEmpty,
                   let selectedAnnotationType = viewModel.selectedAnnotationType,
                   let image = UIImage(named: viewModel.selectedAnnotaions.first?.displayUnit?.parent?.iconName ?? "notes") ?? UIImage(named: "notes") {
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
                        onAnswerQuests: {
                            guard isAnySheetBlockingSelection else {
                                isPresented = true
                                return
                            }
                            isPresented = false
                            dismissOtherSheets()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isPresented = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: viewModel.selectedAnnotaions.count)
                }

                if showPinChoiceOverlay {
                    Color.black.opacity(0.0001)
                        .contentShape(Rectangle())
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture { cancelPinCreation() }

                    PinChoiceCard(
                        onCreateNote: { choosePinFlow(.createNote) },
                        onAddFeature: { choosePinFlow(.addFeature) }
                    )
                    .position(pinChoiceScreenPoint)
                    .ignoresSafeArea()
                    .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .top)))
                    .animation(.easeOut(duration: 0.15), value: showPinChoiceOverlay)
                }

                if showCreateNoteSheet || showAddFeatureSheet, let anchor = pinEditAnchor {
                    // Fixed in screen space — dragging the map underneath it is what
                    // moves the pin; `editedCoordinate` tracks whatever coordinate
                    // currently sits under this point (see CustomMap.Coordinator).
                    // `.ignoresSafeArea()` keeps this aligned with `mapView.bounds` —
                    // the full-screen frame CustomMap itself renders into (it also
                    // ignores safe area) and the space `anchor` was computed in.
                    //
                    // Once a feature preset is picked, its own icon replaces the
                    // generic pin glyph so the marker previews what's about to be added.
                    Group {
                        if let selectedFeaturePreset {
                            PresetIconView(iconName: selectedFeaturePreset.icon, size: 32)
                        } else {
                            Image(systemName: "mappin")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(Asset.Colors.ff0041Red.swiftUIColor)
                        }
                    }
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    .offset(y: -16)
                    .position(anchor)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
                }
            }
            .alert("Zoom in to download data", isPresented: $showZoomInAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The map area is too large. Please zoom in and try again.")
            }
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            screenWidth = proxy.size.width
                            screenSize = proxy.size
                        }
                        .onChange(of: proxy.size.width) { screenWidth = $0 }
                        .onChange(of: proxy.size) { screenSize = $0 }
                }
            )
        .environmentObject(contextualInfo)
        .navigationBarHidden(isPresented)
        .navigationBarItems(leading: EmptyView())
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 10) {
                    Button(action: {
                        dismissOtherSheets()
                        navigateToProfile = true
                    }) {
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
                        // Fixed size so the toolbar measures this item identically on every layout pass
                        // (an unconstrained ScrollView was sized ambiguously, which is what caused the
                        // leading toolbar content to shift/wrap differently after returning from Profile).
                        // Width scales with screen size via `workspaceTitleWidth`; scrolling is preserved
                        // so the full title stays reachable at larger Dynamic Type sizes.
                        .frame(width: workspaceTitleWidth, height: 34)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(L10n.Localizable.workspace): \(selectedWorkspace.title)")
                    }
                }
            }

            // Declared first so iOS 26's toolbar overflow (which collapses trailing-most
            // items first when everything doesn't fit) is least likely to push this one
            // into the "..." menu — its badge/spin animation don't render there.
            ToolbarItem(placement: .topBarTrailing) {
                QuestSyncButton(
                    badgeCount: viewModel.syncFailedElementsCount + viewModel.pendingNotesCount + viewModel.pendingFeaturesCount,
                    isSyncing: isSyncing,
                    action: {
                        guard viewModel.syncFailedElementsCount > 0 || viewModel.pendingNotesCount > 0 || viewModel.pendingFeaturesCount > 0 else {
                            alertIcon = "info.bubble"
                            alertMessage = "No elements to sync"
                            showAlert = true
                            return
                        }

                        if viewModel.pendingNotesCount > 0 {
                            NotesSubmissionManager.resumePendingUploads()
                        }

                        if viewModel.pendingFeaturesCount > 0 {
                            FeatureSubmissionManager.resumePendingUploads()
                        }

                        guard viewModel.syncFailedElementsCount > 0 else { return }
                        isSyncingElements = true
                        DatasyncManager.shared.syncDataToOSM(exclude_gig_tags: false) { _ in
                            isSyncingElements = false
                            viewModel.checkSyncStatus()
                            // This path (unlike a normal answer submission through
                            // QuestProtocols.updateTags) retries whatever changesets
                            // were left pending from an earlier offline/failed sync —
                            // it never sends .answerSynced, so pins for elements that
                            // just got their answers merged (or that are still
                            // excluded as pending) would otherwise sit stale until an
                            // unrelated map pan triggered a refetch. A full refresh
                            // re-evaluates everything against current DB state,
                            // whether this attempt fully succeeded, partially
                            // succeeded, or failed again.
                            viewModel.refreshQuests()
                        }
                    }
                )
            }

            ToolbarItem(placement: .topBarTrailing) {
                accessbilityButton
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    dismissOtherSheets()
                    viewModel.updateOptions(
                        for: mapViewRef?.centerCoordinate
                            ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
                    )
                    viewModel.showSatellitePicker = true
                }) {
                    Label {
                        Text(L10n.Localizable.mapModes)
                    } icon: {
                        Image(systemName: "square.2.layers.3d.bottom.filled")
                            .resizable()
                            .padding(8)
                            .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                            .background(Asset.Colors.e7E3EELightPurpuleBg.swiftUIColor)
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                    }
                }
                .buttonStyle(.plain)
                .labelStyle(.iconOnly)
                .accessibilityLabel(L10n.Localizable.mapModes)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    dismissOtherSheets()
                    showUserSettingsSheet = true
                }) {
                    Label {
                        Text(L10n.Localizable.settings)
                            .foregroundStyle(.red)
                    } icon: {
                        Image(systemName: "gear")
                            .resizable()
                            .padding(8)
                            .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                            .background(Asset.Colors.e7E3EELightPurpuleBg.swiftUIColor)
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                    }
                }
                .buttonStyle(.plain)
                .labelStyle(.iconOnly)
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .onChange(of: showPopover) { newValue in
            if !newValue { shouldShowPolyline = false }
        }
        .onChange(of: isPresented) { newValue in
            if !newValue {
                shouldShowPolyline = false
                if let previousZoom = zoomLevelBeforeQuestSelection {
                    if let previousCenter = centerBeforeQuestSelection {
                        // Animate center and zoom together so the camera eases back to
                        // exactly where it was, instead of zooming out in place first.
                        mapViewRef?.setCenter(previousCenter, zoomLevel: previousZoom, animated: true)
                    } else {
                        mapViewRef?.setZoomLevel(previousZoom, animated: true)
                    }
                    zoomLevelBeforeQuestSelection = nil
                    centerBeforeQuestSelection = nil
                }
            }
        }
        .sheet(isPresented: $showManageQuestSheet) {
            ManageQuestsView()
                // Sized to its own content by ManageQuestsView itself.
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
            .allowMapInteractionBehindSheet()
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
            .interactiveDismissDisabled()
            .presentationDragIndicator(.hidden)
            .applyPresentationSizingPage()
            .focusAccessibilityOnAppear()
            .allowMapInteractionBehindSheet()
        }
        .fullScreenCover(isPresented: $enableAccessibility) {
            AccessibilityModeView(mapViewModel: viewModel)
        }
        .sheet(isPresented: $showCreateNoteSheet) {
            CreateNoteView(
                coordinates: Binding(
                    get: { editedCoordinate ?? tappedCoordinate ?? CLLocationCoordinate2D() },
                    set: { editedCoordinate = $0 }
                ),
                showNotesBox: $showCreateNoteSheet
            )
            .onDisappear {
                pendingAdditionCoordinate = nil
                tappedCoordinate = nil
                editedCoordinate = nil
                pinEditAnchor = nil
            }
            .presentationDetents([.fraction(0.6)])
            .presentationDragIndicator(.visible)
            .applyPresentationSizingPage()
            .allowMapInteractionBehindSheet()
        }
        .sheet(isPresented: $showAddFeatureSheet) {
            AddFeatureView(
                tappedCoordinate: Binding(
                    get: { editedCoordinate ?? tappedCoordinate ?? CLLocationCoordinate2D() },
                    set: { editedCoordinate = $0 }
                ),
                isPresented: $showAddFeatureSheet,
                selectedPreset: $selectedFeaturePreset
            )
            .onDisappear {
                pendingAdditionCoordinate = nil
                tappedCoordinate = nil
                editedCoordinate = nil
                pinEditAnchor = nil
                selectedFeaturePreset = nil
            }
            .presentationDetents([.fraction(0.6)])
            .presentationDragIndicator(.visible)
            .applyPresentationSizingPage()
            .allowMapInteractionBehindSheet()
        }
        .sheet(isPresented: $isPresented) {
            QuestSheetView(viewModel: viewModel, annotationCoordinate: annotationCoordinate)
                .onAppear { shouldShowPolyline = true }
                .presentationDetents([.fraction(0.7), .fraction(0.5), .fraction(0.1)],
                                     selection: $selectedDetent)
                .presentationDragIndicator(.visible)
                .scrollDisabled(false)
                .interactiveDismissDisabled()
                .environmentObject(contextualInfo)
                .applyPresentationSizingPage()
                .allowMapInteractionBehindSheet()
        }
        .onReceive(MapViewPublisher.shared.dismissSheet) { scenario in
            isPresented = false
            switch scenario {
            case .dismissed:
                shouldShowPolyline = false
            case .syncing:
                isSyncingElements = true
            case .synced:
                isSyncingElements = false
                viewModel.checkSyncStatus()
            case .failed:
                isSyncingElements = false
                shouldShowPolyline = false
                viewModel.checkSyncStatus()
            case .hideElement(let elementId, let elementName):
                shouldShowPolyline = false
                viewModel.hideQuest(elementId: elementId, elementName: elementName)
            case .undoDone(let changesetId):
                shouldShowPolyline = false
                viewModel.refreshMapAfterUndoSumbit(storedChangesetId: changesetId)
            case .syncBackground:
                // Fires synchronously the moment a submission starts, before the
                // sync has even reached the server — just a "something is
                // uploading" visual cue. It must NOT touch `items`: the element's
                // merged tags aren't in the local DB yet at this point, so any
                // completeness check here would be against stale, pre-submission
                // data. See .answerSynced for the actual post-sync recheck.
                shouldShowPolyline = false
            case .elementRemoved(let elementID):
                viewModel.refreshMapAfterSubmission(elementId: elementID)
            case .answerSynced(let elementID):
                viewModel.refreshMapAfterAnswerSync(elementId: elementID)
            case .noteSubmitted:
                alertIcon = "checkmark.circle.fill"
                alertMessage = "Note submitted successfully"
                showAlert = true
                viewModel.checkSyncStatus()
            case .notesQueueUpdated:
                viewModel.checkSyncStatus()
            case .notesSyncing:
                isSyncingNotes = true
            case .notesSyncFinished:
                isSyncingNotes = false
                viewModel.checkSyncStatus()
            case .featureSubmitted(let presetName, let matchedQuestUnit):
                alertIcon = "checkmark.circle.fill"
                alertMessage = "\(presetName) added successfully"
                showAlert = true
                if let matchedQuestUnit {
                    viewModel.items.append(matchedQuestUnit)
                }
                viewModel.checkSyncStatus()
            case .featuresQueueUpdated:
                viewModel.checkSyncStatus()
            case .featuresSyncing:
                isSyncingFeatures = true
            case .featuresSyncFinished:
                isSyncingFeatures = false
                viewModel.checkSyncStatus()
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

    /// True while a sheet that keeps the map interactive underneath it is open.
    /// Those sheets let taps reach the map, so CustomMap uses this to avoid presenting
    /// a second `.sheet()` on this view while one is already mid-presentation.
    private var isAnySheetBlockingSelection: Bool {
        isPresented || showPinChoiceOverlay || showCreateNoteSheet ||
            showAddFeatureSheet || viewModel.showSatellitePicker || showUserSettingsSheet
    }

    /// Force-closes every sheet tracked by `isAnySheetBlockingSelection`, except the
    /// quest-answer sheet (`isPresented`), which callers dismiss themselves so they can
    /// re-present it right after.
    private func dismissOtherSheets() {
        if showPinChoiceOverlay {
            showPinChoiceOverlay = false
            tappedCoordinate = nil
            pendingAdditionCoordinate = nil
            editedCoordinate = nil
            setMapGesturesEnabled(true)
        }
        showCreateNoteSheet = false
        showAddFeatureSheet = false
        viewModel.showSatellitePicker = false
        showUserSettingsSheet = false
    }

    /// Enables/disables map pan, pinch-zoom, rotate, and pitch. Frozen while the
    /// pin-choice card is up so the pin (and the card anchored to it) can't drift.
    private func setMapGesturesEnabled(_ enabled: Bool) {
        mapViewRef?.isScrollEnabled = enabled
        mapViewRef?.isZoomEnabled = enabled
        mapViewRef?.isRotateEnabled = enabled
        mapViewRef?.isPitchEnabled = enabled
    }

    /// Screen-space anchor (card center) for the pin-choice card: just below the pin
    /// tip by default, flipped above and clamped horizontally when there isn't room
    /// below, so the card always stays fully on screen.
    private func pinCardAnchor(for coordinate: CLLocationCoordinate2D) -> CGPoint {
        let cardSize = CGSize(width: 220, height: 100)
        let margin: CGFloat = 12
        guard let mapView = mapViewRef, screenSize != .zero else {
            return CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        }
        let pinTip = mapView.convert(coordinate, toPointTo: mapView)
        let spaceBelow = screenSize.height - pinTip.y
        let showBelow = spaceBelow > cardSize.height + margin + 24
        let y = showBelow
            ? pinTip.y + margin + cardSize.height / 2
            : pinTip.y - margin - cardSize.height / 2 - 40
        let minX = cardSize.width / 2 + margin
        let maxX = screenSize.width - cardSize.width / 2 - margin
        let x = min(max(pinTip.x, minX), maxX)
        return CGPoint(x: x, y: y)
    }

    /// Recenters the map (both axes) so `coordinate` lands at the center of the map's
    /// visible area above the Create Note/Add Feature sheet, and returns that anchor
    /// point for the fixed crosshair. Deliberately uses `mapView.bounds` throughout
    /// (never the SwiftUI-measured `screenSize`) since that's the exact coordinate
    /// space `mapView.convert` operates in — mixing the two was what made the pin land
    /// in the wrong spot before.
    private func computePinEditAnchor(for coordinate: CLLocationCoordinate2D) -> CGPoint {
        guard let mapView = mapViewRef else {
            return CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        }
        let visibleHeight = mapView.bounds.height * (1 - Self.noteSheetHeightFraction)
        let anchor = CGPoint(x: mapView.bounds.midX, y: visibleHeight / 2)

        let currentPoint = mapView.convert(coordinate, toPointTo: mapView)
        let currentCenterPoint = CGPoint(x: mapView.bounds.midX, y: mapView.bounds.midY)
        let shiftedPoint = CGPoint(
            x: currentCenterPoint.x + (currentPoint.x - anchor.x),
            y: currentCenterPoint.y + (currentPoint.y - anchor.y)
        )
        let newCenter = mapView.convert(shiftedPoint, toCoordinateFrom: mapView)
        mapView.setCenter(newCenter, animated: true)
        return anchor
    }

    /// User picked "Create Note" or "Add Feature" from the pin-choice card — closes the
    /// card, swaps the map-annotation pin for the fixed on-screen crosshair, recenters
    /// the map so the tapped coordinate sits in the middle of the visible area above
    /// the sheet, and opens the sheet directly. The user can then drag the map
    /// underneath the crosshair to adjust the location for as long as the sheet stays
    /// open — `editedCoordinate` (bound straight into the sheet) tracks it live.
    private func choosePinFlow(_ flow: PinCreationFlow) {
        showPinChoiceOverlay = false
        editedCoordinate = tappedCoordinate
        pendingAdditionCoordinate = nil
        setMapGesturesEnabled(true)
        if let coordinate = tappedCoordinate {
            pinEditAnchor = computePinEditAnchor(for: coordinate)
        }
        switch flow {
        case .createNote:
            showCreateNoteSheet = true
        case .addFeature:
            showAddFeatureSheet = true
        }
    }

    /// User tapped outside the pin-choice card without picking either option.
    private func cancelPinCreation() {
        showPinChoiceOverlay = false
        tappedCoordinate = nil
        pendingAdditionCoordinate = nil
        editedCoordinate = nil
        setMapGesturesEnabled(true)
    }

    /// Both the long-press action sheet and the Create Note/Add Feature sheets that
    /// follow it use a 0.6-fraction bottom sheet at most — panning for that worst case
    /// up front means the pin never gets covered as the user moves between them.
    private static let noteSheetHeightFraction: CGFloat = 0.6

    /// The quest-answer sheet's initial on-screen height (matches its `.fraction(0.7)`
    /// starting detent) — used to keep a selected element, or its full path, clear of
    /// the sheet when it's first presented.
    private static let questSheetHeightFraction: CGFloat = 0.7

    /// Edge padding for fitting a selected way's full path in view: generous enough on
    /// the sides/top to keep it off the screen edges, with extra bottom room for the
    /// quest sheet.
    func questPathEdgePadding() -> UIEdgeInsets {
        let sheetHeight = (mapViewRef?.bounds.height ?? 0) * Self.questSheetHeightFraction
        return UIEdgeInsets(top: 60, left: 40, bottom: sheetHeight + 40, right: 40)
    }

    /// If `coordinate` would currently be hidden behind the bottom sheet, pans the map
    /// just enough to bring it into the remaining visible band above the sheet.
    func ensureCoordinateVisibleAboveSheet(
        _ coordinate: CLLocationCoordinate2D,
        sheetHeightFraction: CGFloat = Self.noteSheetHeightFraction
    ) {
        guard let mapView = mapViewRef else { return }
        let sheetHeight = mapView.bounds.height * sheetHeightFraction
        let visibleHeight = mapView.bounds.height - sheetHeight
        guard visibleHeight > 0 else { return }

        let point = mapView.convert(coordinate, toPointTo: mapView)
        guard point.y > visibleHeight else { return } // already clear of the sheet

        let targetY = visibleHeight / 2
        let deltaY = point.y - targetY
        let currentCenterPoint = CGPoint(x: mapView.bounds.midX, y: mapView.bounds.midY)
        let shiftedPoint = CGPoint(x: currentCenterPoint.x, y: currentCenterPoint.y + deltaY)
        let newCenter = mapView.convert(shiftedPoint, toCoordinateFrom: mapView)
        mapView.setCenter(newCenter, animated: true)
    }

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
        Button(action: {
            dismissOtherSheets()
            enableAccessibility = true
        }) {
            Label {
                Text(L10n.Localizable.screenReaderMode)
                    .foregroundStyle(.red)
            } icon: {
                Image("accessibility")
                    .resizable()
                    .padding(8)
                    .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                    .background(Asset.Colors.e7E3EELightPurpuleBg.swiftUIColor)
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
            }
        }
        .buttonStyle(.plain)
        .labelStyle(.iconOnly)
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
            // Must be set before annotationCoordinate, whose didSet builds the form.
            longQuest.isMultiSelectMode = viewModel.isMultiSelectModeEnabled
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
            if let latest = await longQuest.fetchLatestTagsIfNeeded() {
                if longQuest.isStillConsideredComplete(tags: latest.tags, lastEditedAt: latest.timestamp) {
                    alreadyCompletedMessage = "This element has already been answered by another user."
                    viewModel.refreshQuests()
                } else {
                    // Not complete — the form is about to be shown, so make sure it's
                    // built from the tags we just fetched live, not whatever `tags`
                    // held when the sheet opened (init() runs before this fetch).
                    longQuest.refreshTags(latest.tags)
                }
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
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(conflict.elementTypeName)
                                .font(.headline)
                            Text("ID: \(String(conflict.elementId))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)

                    Text("This element was changed by someone else while you were answering. Choose which value to keep for each tag below.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                ForEach(conflict.conflicts) { tag in
                    let question = questionText(forTagKey: tag.key)
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
                                .accessibilityLabel("\(question). Your answer: \(tag.answeredValue)")
                            (Text("Existing value: ")
                                .foregroundColor(Asset.Colors.a2A2A2Gray.swiftUIColor)
                             + Text(tag.existingValue)
                                .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                                .fontWeight(.semibold))
                                .tag(TagResolutionChoice.useServer)
                                .accessibilityLabel("\(question). Existing value on the server: \(tag.existingValue)")
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                        .accessibilityHint("Choose which value to keep for this tag")
                    } header: {
                        Text(question)
                            .fontWeight(.semibold)
                            .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                            .accessibilityAddTraits(.isHeader)
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
                    .accessibilityHint("Discards your choices and leaves this element unsynced")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        conflict.resolve(.resolved(choices))
                        dismiss()
                    }
                    .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                    .accessibilityHint("Applies your chosen values for each tag and continues syncing")
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
    /// A created element was deleted via undo — remove its pin, if it has one.
    case elementRemoved(Int)
    /// An element's answers were successfully synced to the server (local tags
    /// are now merged and persisted) — re-check whether it should still show a
    /// pin, rather than assuming any submission means "done, hide it".
    case answerSynced(Int)
    case noteSubmitted
    case notesQueueUpdated
    case notesSyncing
    case notesSyncFinished
    /// A queued feature was created (possibly well after Submit was tapped, if it had
    /// to wait offline) — the preset name for the confirmation, plus a quest pin to
    /// add quietly if the new element satisfies a LongForm quest_query. Never opens
    /// the quest sheet itself; by the time this fires the user may be doing anything.
    case featureSubmitted(String, DisplayUnitWithCoordinate?)
    case featuresQueueUpdated
    case featuresSyncing
    case featuresSyncFinished
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

/// Small card anchored next to a freshly-dropped pin, offering "Create Note" or
/// "Add Feature" — replaces the old bottom sheet so the choice reads as belonging
/// to the pin itself rather than as a separate modal.
struct PinChoiceCard: View {
    var onCreateNote: () -> Void
    var onAddFeature: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onCreateNote) {
                Text("Create Note")
                    .font(FontFamily.Lato.regular.swiftUIFont(size: 16, relativeTo: .headline))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
            .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)

            Divider()

            Button(action: onAddFeature) {
                Text("Add Feature")
                    .font(FontFamily.Lato.regular.swiftUIFont(size: 16, relativeTo: .headline))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
            .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
        }
        .frame(width: 220)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
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
