//
//  CustomAlert.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 01/02/24.
//

import SwiftUI

// A custom alert view that allows customization of its title, content, buttons, and dimensions.
struct CustomAlert<ContentItem: View>: View {
    let title: String
    let content: ContentItem
    let leftActionText: String?
    let rightActionText: String
    let leftButtonAction: () -> Void
    let rightButtonAction: () -> Void
    let height: CGFloat
    let width: CGFloat
    
    // Initializer
    init(title: String, @ViewBuilder content: () -> ContentItem, leftActionText: String?, rightActionText: String, leftButtonAction: @escaping () -> Void, rightButtonAction: @escaping () -> Void, height: CGFloat, width: CGFloat) {
        self.title = title
        self.content = content()
        self.leftActionText = leftActionText
        self.rightActionText = rightActionText
        self.leftButtonAction = leftButtonAction
        self.rightButtonAction = rightButtonAction
        self.height = height
        self.width = width
    }
    
    // The body of the alert, defined as a ZStack to overlay content on a semi-transparent background.
    var body: some View {
        ZStack {
            Color.black.opacity(0.50) // Semi-transparent black background to dim the rest of the UI.
                .edgesIgnoringSafeArea(.all) // Ignore safe area to cover the entire screen.
            
            VStack(spacing: 0) {
                if !title.isEmpty {
                    // Display the alert title if provided.
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        .padding(.horizontal, 16)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .leading)
                }
                
                // Display the custom content of the alert.
                content
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .leading)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 16)
                
                // Horizontal stack to hold the action buttons.
                HStack(spacing: 0) {
                    if let leftActionText = leftActionText {
                        // Left button with optional action.
                        Button(action: {
                            leftButtonAction()
                        }) {
                            Text(leftActionText)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.orange)
                                .multilineTextAlignment(.center)
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        }
                    }
                    
                    // Right button with required action.
                    Button(action: {
                        rightButtonAction()
                    }) {
                        Text(rightActionText)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50) // Set fixed height for the button row.
                .padding([.horizontal, .bottom], 0)
            }
            .frame(width: width, height: height) // Set dimensions for the alert.
            .background(Color.white)
            .cornerRadius(10)
        }
        .zIndex(2) // Set the z-index to ensure the alert is displayed above other views.
    }
}

#Preview {
    CustomAlert(title: "", content: {Text("Test")}, leftActionText: "", rightActionText: "", leftButtonAction: {}, rightButtonAction: {}, height: 200,width: 270)
}
