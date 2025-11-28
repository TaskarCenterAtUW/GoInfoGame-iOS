//
//  CrossMarkButton.swift
//  GoInfoGame
//
//  Created by Prashamsa on 28/11/25.
//

import SwiftUI

struct CrossMarkButton: View {
    var onDismiss: (() -> Void)?
    
    init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        Button(action: {
            onDismiss?()
        }, label: {
            Image(systemName: "xmark.circle")
                .resizable()
                .frame(width: 25, height: 25)
                .foregroundStyle(Asset.Colors.accentPink.swiftUIColor)
        })
    }
}

#Preview {
    CrossMarkButton()
}
