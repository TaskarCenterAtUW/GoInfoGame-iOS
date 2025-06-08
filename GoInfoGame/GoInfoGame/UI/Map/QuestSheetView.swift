//
//  QuestSheetView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 08/06/25.
//

import SwiftUI
import CoreLocation

struct QuestSheetView: View {
    @ObservedObject var viewModel: MapViewModel
    let annotationCoordinate: CLLocationCoordinate2D?

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
    }
}
