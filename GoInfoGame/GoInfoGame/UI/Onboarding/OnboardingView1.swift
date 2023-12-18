//
//  OnboardingView1.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 18/12/23.
//

import SwiftUI

struct OnboardingView1: View {
    var body: some View {
        VStack {
            Image("osmlogo")
                .resizable()
                .scaledToFit()
            Text("Welcome to OpenStreetMap")
                .font(.title)
                .fontWeight(.bold)
                .fixedSize()
            Text("the free wiki world map")
                
            
            Text("GoInfoGame makes it easy to contribute to OpenStreetMap. It automatically looks for missing details in your vicinity: bicycle lanes, house numbers, opening hours and much more...")
                .padding()
            
        }
        .padding()
    }
}
struct OnboardingView1_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView1()
    }
}
