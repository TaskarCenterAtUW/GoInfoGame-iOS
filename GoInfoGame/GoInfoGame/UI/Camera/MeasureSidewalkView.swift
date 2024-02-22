//
//  MeasureSidewalkView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 21/02/24.
//

import SwiftUI

struct MeasureSidewalkView: View {
    
    @State private var measuring = false
    
    var body: some View {
        VStack {
            ARMeasuringView(measuring: $measuring)
            
        }
    }
}

#Preview {
    MeasureSidewalkView()
}
