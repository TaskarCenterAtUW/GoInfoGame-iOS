//
//  FloatingActionButton.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 17/01/25.
//

import SwiftUI

struct FloatingActionButtonStack: View {
    
    @State private var showBottomSheet = false
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack {
                    Button(action: {
                        showBottomSheet.toggle()
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 25))
                            .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                            .frame(width: 54, height: 54)
                            .background(.white)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                          
                    }
                    .sheet(isPresented: $showBottomSheet) {
                        ManageQuestsView()
                            .presentationDetents([.fraction(0.85)])
                            .interactiveDismissDisabled()
                            .presentationDragIndicator(.hidden)
                            .applyPresentationSizingPage()
                    }
                }
                .offset(x: -25, y: 10)

               
            }
        }
    }
}
#Preview {
    FloatingActionButtonStack()
}
