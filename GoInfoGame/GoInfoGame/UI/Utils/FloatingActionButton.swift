//
//  FloatingActionButton.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 17/01/25.
//

import SwiftUI

struct FloatingActionButton: View {
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                NavigationLink(destination: QuestCategoryListView()) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 25))
                        .foregroundColor(.white)
                }
                .frame(width: 40, height: 40)
                .background(Color(red: 135/255, green: 62/255, blue: 242/255))
                .cornerRadius(30)
                .shadow(radius: 10)
                .offset(x: -25, y: 10)
            }
        }
    }
}
#Preview {
    FloatingActionButton()
}
