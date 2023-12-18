//
//  OnboardingView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 07/12/23.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("isOnboarding") var isOnboarding: Bool = true
    @State private var currentPage: Int = 1
    @State private var isLetsGoButtonClicked: Bool = false
    
    var body: some View {
        VStack {
            if isOnboarding {
                TabView(selection: $currentPage) {
                    OnboardingView1()
                        .tag(1)
                    
                    OnboardingView2()
                        .tag(2)
                    
                    OnboardingView3()
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle())
                .padding(.vertical, 20)
                
                // Pagination Indicator
                HStack(spacing: 8) {
                    ForEach(1...3, id: \.self) { page in
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundColor(page == currentPage ? .blue : .gray)
                    }
                }
                .padding(.top, 8)
                
                if currentPage == 3 {
                    NavigationLink(destination: HomeMapView(), isActive: $isLetsGoButtonClicked) {
                        EmptyView()
                    }
                    
                    Button(action: {
                        isOnboarding = false
                        isLetsGoButtonClicked = true
                    }) {
                        HStack(spacing: 8) {
                            Text("Let's Go!")
                            
                            Image(systemName: "arrow.right.circle")
                                .imageScale(.large)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().strokeBorder(Color.black, lineWidth: 1.25)
                        )
                    }
                    .accentColor(Color.black)
                }
            } else {
                NavigationLink(destination: HomeMapView(), isActive: $isLetsGoButtonClicked) {
                    EmptyView()
                }
                .hidden()
            }
        }
        .padding()
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
