//
//  OnboardingView3.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 18/12/23.
//

import SwiftUI

struct OnboardingView3: View {
    var body: some View {
        VStack(spacing: 20) {
            Image("osmlogo")
                .resizable()
                .scaledToFit()
          
            Text("Whenever you are uncertain, you can always reply 'Cant say' and leave a note.")
                
            
            Text("Finally, remember to stay safe. Be aware of your surroundings and don't enter private property.")
            
            Text("Happy Mapping!")
                .bold()
             
        }
        .padding()
    }
}

struct OnboardingView3_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView3()
    }
}
