//
//  OnboardingView2.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 18/12/23.
//

import SwiftUI

struct OnboardingView2: View {
    var body: some View {
        VStack(spacing: 20) {
            Image("osmlogo")
                .resizable()
                .scaledToFit()
          
            Text("Once found, the missing details will appear on your map as quests.")
                
            
            Text("You can start solving them right away and later login to publish your answers.")
            
            Text("Location permissions is needed to show your position on the map and download data in your vicinity.")
             
        }
        .padding()
    }
}

struct OnboardingView2_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView2()
    }
}
