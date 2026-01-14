//
//  FloatingActionButton.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 17/01/25.
//

import SwiftUI

struct FloatingActionButton: View {
    let systemName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Image(systemName: systemName)
                .font(.system(size: 25))
                .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                .frame(width: 54, height: 54)
                .background(.white)
                .clipShape(Circle())
                .shadow(radius: 10)
        }
    }
}
#Preview {
    FloatingActionButton(systemName: "slider.horizontal.3") {
        
    }
}
