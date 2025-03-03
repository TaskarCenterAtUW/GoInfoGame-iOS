//
//  FloatingActionButton.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 17/01/25.
//

import SwiftUI

struct FloatingActionButtonStack: View {
    
    var mapButtonAction: () -> ()
    var useBingMaps: Bool
    @State private var showBottomSheet = false
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack {
                    MapSwitcherButton(action: mapButtonAction, useBingMaps: useBingMaps)
                    
                    Button(action: {
                        showBottomSheet.toggle()
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 25))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color(red: 135/255, green: 62/255, blue: 242/255))
                            .cornerRadius(30)
                            .shadow(radius: 10)
                          
                    }
                    .sheet(isPresented: $showBottomSheet) {
                        QuestCategoryListView()
                            .presentationDetents([.fraction(0.85)])
                            .presentationDragIndicator(.visible)
                    }
                }
                .offset(x: -25, y: 10)

               
            }
        }
    }
}
#Preview {
    FloatingActionButtonStack(mapButtonAction: {}, useBingMaps: false)
}

struct MapSwitcherButton: View {
    
    var action: () -> ()
    var useBingMaps: Bool
    
    var body: some View {
        Button(action:
                action
        ) {
            ZStack {
                Circle()
                    .fill(Color(red: 135/255, green: 62/255, blue: 242/255))
                    .frame(width: 40, height: 40)
                    .shadow(radius: 5)
                
                Image(systemName: useBingMaps ? "square.3.layers.3d" : "map")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
        }
        .padding([.bottom], 15)
    }
}
