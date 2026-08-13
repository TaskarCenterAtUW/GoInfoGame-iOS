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
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)

        }
        .frame(minWidth: 150, minHeight: 150)
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
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
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
                Image(systemName: "xmark.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
                    .foregroundStyle(Asset.Colors.accentPink.swiftUIColor)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            })
            .accessibilityLabel("Dismiss")
        }
    }
}

#Preview(body: {
    LongFormDismissButtonView {
        
    }
})
