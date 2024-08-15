//
//  LoadingView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 29/01/24.
//

import SwiftUI

struct ActivityView: View {
    
    let activityText: String
    
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue)) 
                .padding(20)
            
            Text(activityText)
                .foregroundColor(.gray)
                .font(.headline)
                .padding(.bottom, 10)

        }
        .frame(width: 150, height: 150)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white).shadow(radius: 5))
    }
}

//TODO: Move it to new file
struct DismissButtonView: View {
    let dismissAction: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                dismissAction()
                MapViewPublisher.shared.dismissSheet.send(.dismissed)
                
            }, label: {
                Text("Dismiss")
                    .foregroundStyle(.orange)
            })
            .padding([.top], 30)
            .padding([.trailing], 15)
        }
    }
}


struct LongFormDismissButtonView: View {
    let dismissAction: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                dismissAction()
                MapViewPublisher.shared.dismissSheet.send(.dismissed)
                
            }, label: {
                Image("long-form-dismiss")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
            })
            
        }
    }
}
