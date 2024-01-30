//
//  LoadingView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 29/01/24.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue)) 
                .padding(20)
            
            Text("Loading...")
                .foregroundColor(.gray)
                .font(.headline)
                .padding(.bottom, 10)

        }
        .frame(width: 150, height: 150)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white).shadow(radius: 5))
    }
}
