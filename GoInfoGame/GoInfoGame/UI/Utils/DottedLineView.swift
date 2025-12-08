//
//  DottedLineView.swift
//  GoInfoGame
//
//  Created by Prashamsa on 28/11/25.
//

import SwiftUI

struct DottedLine: View {
    var color: Color = Asset.Colors.huskyPurple.swiftUIColor
    var thickness: CGFloat = 1
    var dashLength: CGFloat = 1
    var dashGap: CGFloat = 2

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                // Start the line at the leading edge (x=0)
                path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                
                // Draw the line to the trailing edge (x = full width)
                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
            }
            .stroke(
                color,
                style: SwiftUI.StrokeStyle(
                    lineWidth: thickness,
                    lineCap: .round,
                    dash: [dashLength, dashGap]
                )
            )
        }
        .frame(height: thickness)
    }
}

#Preview {
    DottedLine()
}
