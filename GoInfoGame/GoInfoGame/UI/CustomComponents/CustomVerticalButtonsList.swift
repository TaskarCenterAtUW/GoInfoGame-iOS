//
//  CustomVerticalButtonsList.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 01/02/24.
//

import SwiftUI

// A vertically stacked list of buttons with customizable labels and actions.
struct CustomVerticalButtonsList: View {
    let buttons: [ButtonInfo] // Array of ButtonInfo representing each button.
    let selectionChanged: (ButtonInfo?) -> Void // Closure to handle button selection changes.
    
    // The body of the view, which displays a vertical list of buttons.
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(buttons) { buttonInfo in
                Button(action: {
                    selectionChanged(buttonInfo) // Call the provided closure when a button is tapped.
                }) {
                    Text(buttonInfo.label) // Display the button label.
                }
            }
        }
        .padding(.top, 20)
    }
}

// Structure to represent information about a button.
struct ButtonInfo: Identifiable {
    let id: Int // Unique identifier for the button.
    let label: String // Label text displayed on the button.
}
