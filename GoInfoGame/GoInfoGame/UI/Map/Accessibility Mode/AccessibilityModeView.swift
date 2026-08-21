//
//  AccessibilityModeView.swift
//  GoInfoGame
//
//  Created by Prashamsa on 24/11/25.
//

import SwiftUI
import UIKit
import Foundation

struct AccessibilityModeView: View {
    @Environment(\.dismiss) var dismiss
    @State var showLongFrom: Bool = false
    @ObservedObject var mapViewModel: MapViewModel
    @StateObject var viewModel: AccessibilityModeViewModel
    @State private var selectedDetent: PresentationDetent = .fraction(0.8)
    @State var navigateToUndo: Bool = false
    @State private var showBottomSheet = false
    @State private var showElemntDeletedAlert: Bool = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init (mapViewModel: MapViewModel) {
        self.mapViewModel = mapViewModel
        _viewModel = StateObject(wrappedValue: AccessibilityModeViewModel(mapViewModel: mapViewModel))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.nearestQuest.isEmpty {
                    NoQuestsNearView()
                } else {
                    // Everything lives inside one continuous List (as sections), so it
                    // all scrolls together — the quest-count header and the bottom bar
                    // used to be fixed, non-scrolling content around the List, which at
                    // large accessibility text could grow tall enough to push the List
                    // (and the bottom buttons) off-screen with nothing to scroll to
                    // reach them.
                    List {
                        Section {
                            HStack(alignment: .center, content: {
                                numberOfQuestsView
                                Spacer()
                                refreshListButton
                            })
                            DottedLine()
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))

                        Section {
                            ForEach(viewModel.nearestQuest, id: \.self) { item in
                                Button {
                                    viewModel.selectedQuest = item.quest
                                    mapViewModel.selectedQuest = item.quest.displayUnit
                                } label: {
                                    NearestQuestCard(quest: item)
                                        .cornerRadius(16)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .listRowInsets(EdgeInsets())
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                        Section {
                            DottedLine()
                            bottomBar
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .listRowSpacing(20)
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text(L10n.Localizable.screenReaderMode)
                        .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                        .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        // .principal centers relative to the leading/trailing group widths, so its
                        // apparent alignment shifted depending on how many trailing items existed —
                        // fragile. An explicit leading frame keeps this stable regardless of that.
                        .frame(width: 190, alignment: .leading)
                        .accessibilityLabel(L10n.Localizable.screenReaderMode)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    filterButton
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    closeButton
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .onChange(of: navigateToUndo) { newValue in
            if newValue {
                viewModel.stopMonitoring()
            } else {
                viewModel.startMonitoring()
            }
        }
        .onAppear() {
            viewModel.startMonitoring()
        }
        .focusAccessibilityOnAppear()
        .onDisappear() {
            viewModel.stopMonitoring()
        }
        .sheet(isPresented: $showLongFrom) {
            QuestSheetView(viewModel: mapViewModel, annotationCoordinate: viewModel.selectedQuest?.coordinateInfo)
                .presentationDetents([.fraction(0.8), .fraction(0.5), .fraction(0.1)], selection: $selectedDetent)
                .presentationDragIndicator(.visible)
                .scrollDisabled(false)
                .interactiveDismissDisabled()
                .applyPresentationSizingPage()
                .focusAccessibilityOnAppear()
        }
        .onChange(of: mapViewModel.items) { _ in
            if let lkl = viewModel.lastKnownLocation {
                viewModel.filterQuestsNerestToUser(location: lkl)
            }
        }
        .onReceive(QuestsPublisher.shared.elementDeleted, perform: { _ in
            showElemntDeletedAlert = true
        })
        .alert("Element is deleted from the server.", isPresented: $showElemntDeletedAlert) {
            Button("OK", role: .cancel) { }
        }
        .sheet(item: $viewModel.selectedQuest) { _ in
            if let quest = viewModel.selectedQuest {
                QuestSelectionConfirmationView(questType: quest.displayUnit.parent?.elementType ?? "", isAutoSelected: viewModel.isQuestAutoSelected) {
                    if viewModel.isQuestAutoSelected {
                        viewModel.autoSelectionCanceledIDs.insert(quest.id)
                        viewModel.isQuestAutoSelected = false
                    }
                    self.showLongFrom = true
                } onHideQuest: {
                    if viewModel.isQuestAutoSelected {
                        viewModel.autoSelectionCanceledIDs.insert(quest.id)
                        viewModel.isQuestAutoSelected = false
                    }
                    mapViewModel.hideQuest(elementId: String(quest.id), elementName: quest.displayUnit.parent?.elementType ?? "")
                } onClose: {
                    if viewModel.isQuestAutoSelected {
                        viewModel.autoSelectionCanceledIDs.insert(quest.id)
                        viewModel.isQuestAutoSelected = false
                    }
                }
                .background(Color(red: 248/255, green: 248/255, blue: 248/255))
                // Sized to its own content by QuestSelectionConfirmationView itself.
                .interactiveDismissDisabled()
                .presentationDragIndicator(.hidden)
                .applyPresentationSizingPage()
                .focusAccessibilityOnAppear()
            }
        }
        .fullScreenCover(isPresented: $navigateToUndo) {
            UndoEditsView()
                .focusAccessibilityOnAppear()
        }
        // Tell VoiceOver this view is modal so it confines focus to the presented accessibility UI
        .accessibilityAddTraits(.isModal)
    }
    
    private var refreshListButton: some View {
        Button {
            viewModel.stopMonitoring()
            viewModel.startMonitoring()
        } label: {
            HStack {
                Image(systemName:"arrow.clockwise")
                    .resizable()
                    .frame(width: 14, height: 14)
                Text(L10n.Localizable.refreshList)
                    .font(FontFamily.Lato.semibold.swiftUIFont(size: 12, relativeTo: .body))
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(L10n.Localizable.refreshList)
                
            }
            .foregroundColor(.white)
            .padding(.leading, 4)
            .padding(.trailing, 4)
            .padding(10)
            .frame(minHeight: 44)
            .background(Asset.Colors.huskyPurple.swiftUIColor)
            .cornerRadius(10)
        }
        // Now inside a List row — without this, List applies its own default
        // button/selection styling, which can make taps unreliable.
        .buttonStyle(.plain)
    }
    
    private var numberOfQuestsView: some View {
        VStack(alignment: .leading, spacing: 5.0) {
            Text(L10n.Localizable.numberOfQuests + " \(viewModel.nearestQuest.count)")
                .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                .foregroundColor(Asset.Colors._42526ETextFieldText.swiftUIColor)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(L10n.Localizable.numberOfQuests + " \(viewModel.nearestQuest.count)")

            Text(L10n.Localizable.selectTheQuestToStartAnswering)
                .font(FontFamily.Lato.medium.swiftUIFont(size: 14, relativeTo: .subheadline))
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(L10n.Localizable.selectTheQuestToStartAnswering)
        }
    }
    
    private var closeButton: some View {
        CrossMarkButton {
            dismiss()
        }
        .accessibilityLabel(L10n.Localizable.closeScreenReaderModeScreen)
    }
    
    private var filterButton: some View {
        Button(action: {
            showBottomSheet.toggle()
        }) {
            Image("tune")
                .font(.title3)
                .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                .accessibilityLabel(L10n.Localizable.manageQuests)
        }
        .sheet(isPresented: $showBottomSheet) {
            ManageQuestsView()
                // Sized to its own content by ManageQuestsView itself.
                .interactiveDismissDisabled()
                .presentationDragIndicator(.hidden)
                .applyPresentationSizingPage()
                .focusAccessibilityOnAppear()
        }
    }
    private var undoEditButton: some View {
        Button {
            self.navigateToUndo = true
        } label: {
            HStack {
                Image(systemName: "arrow.uturn.backward")
                Text(L10n.Localizable.undoEdits)
                    .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(L10n.Localizable.undoEdits)
            }
            .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
            .padding(10)
            .frame(minHeight: 44)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Asset.Colors.huskyPurple.swiftUIColor, lineWidth: 2)
        )
        // These two share a row (or a stack at accessibility sizes) inside a List
        // Section — without this, List's default button styling makes taps on either
        // one unreliable.
        .buttonStyle(.plain)
    }

    private var goToMapView: some View {
        Button {
            dismiss()
        } label: {
            HStack {
                Image(systemName: "arrow.left")
                Text(L10n.Localizable.goBackToMapView)
                    .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(L10n.Localizable.goBackToMapView)
            }
            .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
            .padding(10)
            .frame(minHeight: 44)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Asset.Colors.huskyPurple.swiftUIColor, lineWidth: 2)
        )
        .buttonStyle(.plain)
    }

    private var bottomBar: some View {
        // Side by side, neither button has enough width at large accessibility text
        // sizes to fit its label as a whole word, so both wrap mid-word. Stacking them
        // instead gives each the full row width.
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 12) {
                    undoEditButton
                    goToMapView
                }
            } else {
                HStack {
                    undoEditButton
                    Spacer()
                    goToMapView
                }
            }
        }
        .padding(.leading)
        .padding(.trailing)
        .padding(.top)
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
        AccessibilityModeView(mapViewModel: MapViewModel(workspace: workspace))
    } else {
      EmptyView()
    }
    
}
