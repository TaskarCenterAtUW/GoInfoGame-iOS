//
//  AccessibilityModeView.swift
//  GoInfoGame
//
//  Created by Prashamsa on 24/11/25.
//

import SwiftUI

struct AccessibilityModeView: View {
    @Environment(\.dismiss) var dismiss
    @State var showLongFrom: Bool = false
    @ObservedObject var mapViewModel: MapViewModel
    @StateObject var viewModel: AccessibilityModeViewModel
    @State private var selectedDetent: PresentationDetent = .fraction(0.8)
    @State var selectedQuest: DisplayUnitWithCoordinate?
    
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
                    VStack(alignment: .leading, content: {
                        HStack(alignment: .center, content: {
                            numberOfQuestsView
                            Spacer()
                            refreshListButton
                            
                        })
                        .padding(.bottom)
                        
                        DottedLine()
                        
                        List {
                            ForEach(viewModel.nearestQuest, id: \.self) { item in
                                Button {
                                    self.selectedQuest = item.quest
                                    mapViewModel.selectedQuest = item.quest.displayUnit
                                } label: {
                                    NearestQuestCard(quest: item)
                                        .cornerRadius(16)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .listRowInsets(EdgeInsets())
                            }
                            
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .listRowSpacing(20)
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                        
                        DottedLine()
                        
                        bottomBar
                    })
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text(L10n.Localizable.accessibilityMode)
                        .font(FontFamily.Lato.bold.swiftUIFont(size: 16))
                        .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    closeButton
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .onAppear() {
            viewModel.startMonitoring()
        }
        .onDisappear() {
            viewModel.stopMonitoring()
        }
        .sheet(isPresented: $showLongFrom) {
            QuestSheetView(viewModel: mapViewModel, annotationCoordinate: selectedQuest?.coordinateInfo)
                .presentationDetents([.fraction(0.8), .fraction(0.5), .fraction(0.1)], selection: $selectedDetent)
                .presentationDragIndicator(.visible)
                .scrollDisabled(false)
                .interactiveDismissDisabled()
                .applyPresentationSizingPage()
        }
        .onChange(of: mapViewModel.items) { _ in
            if let lkl = viewModel.lastKnownLocation {
                viewModel.filterQuestsNerestToUser(location: lkl)
            }
        }
        .sheet(item: $selectedQuest) { _ in
            if let quest = selectedQuest {
                QuestSelectionConfirmationView(questType: quest.displayUnit.parent?.elementType ?? "") {
                    self.showLongFrom = true
                } onHideQuest: {
                    mapViewModel.hideQuest(elementId: String(quest.id), elementName: quest.displayUnit.parent?.elementType ?? "")
                } onClose: {
                    
                }
                .background(Color(red: 248/255, green: 248/255, blue: 248/255))
                .presentationDetents([.fraction(0.36)])
                .interactiveDismissDisabled()
                .presentationDragIndicator(.hidden)
                .applyPresentationSizingPage()
            }
        }
    }
    
    private var refreshListButton: some View {
        Button {
            
        } label: {
            HStack {
                Image(systemName:"arrow.clockwise")
                    .resizable()
                    .frame(width: 14, height: 14)
                Text(L10n.Localizable.refreshList)
                    .font(FontFamily.Lato.semibold.swiftUIFont(fixedSize: 12))
                
            }
            .foregroundColor(.white)
            .padding(.leading, 4)
            .padding(.trailing, 4)
            .padding(10)
            .background(Asset.Colors.huskyPurple.swiftUIColor)
            .cornerRadius(10)
        }
    }
    
    private var numberOfQuestsView: some View {
        VStack(alignment: .leading, spacing: 5.0, content: {
            Text(L10n.Localizable.numberOfQuests + " \(viewModel.nearestQuest.count)")
                .font(FontFamily.Lato.bold.swiftUIFont(size: 16))
                .foregroundColor(Asset.Colors._42526ETextFieldText.swiftUIColor)
            Text(L10n.Localizable.selectTheQuestToStartAnswering)
                .font(FontFamily.Lato.medium.swiftUIFont(size: 14))
                .foregroundColor(Asset.Colors._42526ETextFieldText.swiftUIColor)
        })
    }
    
    private var closeButton: some View {
        CrossMarkButton {
            dismiss()
        }
    }
    
    private var undoEditButton: some View {
        Button {
            
        } label: {
            HStack {
                Image(systemName: "arrow.uturn.backward")
                Text(L10n.Localizable.undoEdits)
                    .font(FontFamily.Lato.bold.swiftUIFont(fixedSize: 16))
            }
            .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
            .padding(10)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Asset.Colors.huskyPurple.swiftUIColor, lineWidth: 2) // Stroke it with red color and desired thickness
        )
    }
    
    private var goToMapView: some View {
        Button {
            dismiss()
        } label: {
            HStack {
                Image(systemName: "arrow.left")
                Text(L10n.Localizable.goBackToMapView)
                    .font(FontFamily.Lato.bold.swiftUIFont(fixedSize: 16))
            }
            .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
            .padding(10)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Asset.Colors.huskyPurple.swiftUIColor, lineWidth: 2) // Stroke it with red color and desired thickness
        )
    }
    
    private var bottomBar: some View {
        HStack {
            undoEditButton
            Spacer()
            goToMapView
        }
        .padding(.leading)
        .padding(.trailing)
        .padding(.top)
    }
}

//#Preview {
//    AccessibilityModeView()
//}
