//
//  QuestsListUIView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 04/01/24.
//

import SwiftUI

struct QuestsListUIView : View {
    @StateObject private var viewModel = MapViewModel()
    @State var selectedQuest: DisplayUnit?
    
    var body: some View {
        ZStack{
            List {
                Section(header: Text("Quests Explorer")) {
                    ForEach(viewModel.items.indices, id: \.self) { index in
                        VStack(alignment: .leading) {
                            Text(viewModel.items[index].displayUnit.description).font(.subheadline)
                            Text(viewModel.items[index].subheading).font(.caption2)
                        }
                        .onTapGesture {
                            selectedQuest = viewModel.items[index].displayUnit
                        }
                    }
                }
            }
            
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                LoadingView()
            }}
        .sheet(item: $selectedQuest) { selectedQuest in
            if #available(iOS 16.0, *) {
                selectedQuest.parent?.form.presentationDetents(getSheetSize(sheetSize: selectedQuest.sheetSize ?? .MEDIUM))
            } else {
                // Nothing here
            }
        }
    }
}

@available(iOS 16.0, *)
func getSheetSize(sheetSize: SheetSize) -> Set<PresentationDetent> {
    if sheetSize == .SMALL {
        return [.height(250)]
    } else if sheetSize == .LARGE {
        return [.height(600)]
    } else if sheetSize == .XLARGE {
        return [.height(800)]
    } else {
        return [.medium, .large]
    }
}
//}

#Preview {
    QuestsListUIView()
}
