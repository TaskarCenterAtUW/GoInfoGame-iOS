//
//  MeasureSidewalkView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 21/02/24.
//

import SwiftUI

struct MeasureSidewalkView: View {
    var body: some View {
        VStack {
            CameraView()
                .frame(height: 300)
            Button("Measure sidewalk") {
                
            }
        }
    }
}

#Preview {
    MeasureSidewalkView()
}
