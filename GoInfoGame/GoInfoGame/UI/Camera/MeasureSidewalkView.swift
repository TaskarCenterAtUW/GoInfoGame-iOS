//
//  MeasureSidewalkView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 21/02/24.
//

import SwiftUI

struct MeasureSidewalkView: View {
    
    @State private var aimLabelHidden = true
    @State private var notReadyLabelHidden = false
    @State private var startMeasuring = false
    @State private var resultLabelText = ""
    
    var body: some View {
        ZStack {
           Spacer()
            MeasureWidthContainer(aimLabelHidden: $aimLabelHidden, notReadyLabelHidden: $notReadyLabelHidden, startMeasuring: $startMeasuring, resultLabelText: $resultLabelText)
            VStack {
                Spacer()
                Text("+")
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
                    .padding()
                    .font(.largeTitle)
                
                Spacer()
                Button {
                    toggleMeasuring()
                } label: {
                    Text("Measure")
                        .fontWeight(.bold)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
                .padding()
            }
        }
        if !resultLabelText.isEmpty {
            VStack {
                Text("Width is: \(resultLabelText)")
                    .padding()
                    .foregroundColor(.white)
                    .font(.headline)
            }
        }
            
    }
    
    func toggleMeasuring() {
        startMeasuring.toggle()
    }
}

#Preview {
    MeasureSidewalkView()
}