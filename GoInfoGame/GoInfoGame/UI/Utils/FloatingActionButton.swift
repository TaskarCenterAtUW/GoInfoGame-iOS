//
//  FloatingActionButton.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 17/01/25.
//

import SwiftUI

struct FloatingActionButton: View {
    var systemName: String? = nil
    var name: String? = nil
    var iconSize: CGFloat = 25
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Group {
                if let name = name {
                    Image(name)
                } else if let systemName = systemName {
                    Image(systemName: systemName)
                } else {
                    Image(systemName: "questionmark")
                }
            }
            .font(.system(size: iconSize))
            .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
            .frame(width: 44, height: 44)
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
