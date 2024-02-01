//
//  CustomAlert.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 01/02/24.
//

import SwiftUI

struct CustomAlert<ContentItem: View>: View {
    let title: String
    let content: ContentItem
    let leftActionText: String?
    let rightActionText: String
    let leftButtonAction: (() -> Void)?
    let rightButtonAction: () -> Void
    let height: CGFloat
    let width: CGFloat
    
    init(title: String, @ViewBuilder content: () -> ContentItem, leftActionText: String?, rightActionText: String, leftButtonAction: (() -> Void)? = nil, rightButtonAction: @escaping () -> Void, height: CGFloat, width: CGFloat) {
        self.title = title
        self.content = content()
        self.leftActionText = leftActionText
        self.rightActionText = rightActionText
        self.leftButtonAction = leftButtonAction
        self.rightButtonAction = rightButtonAction
        self.height = height
        self.width = width
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.50)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        .padding(.horizontal, 16)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                content
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .leading)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 16)
                   
                
                HStack(spacing: 0) {
                    if let leftActionText = leftActionText {
                        Button(action: {
                            leftButtonAction?()
                        }) {
                            Text(leftActionText)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.orange)
                                .multilineTextAlignment(.center)
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        }
                    }
                    
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
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                .padding([.horizontal, .bottom], 0)
            }
            .frame(width: width, height: height)
            .background(Color.white)
            .cornerRadius(10)
        }
        .zIndex(2)
    }
}

#Preview {
    CustomAlert(title: "", content: {Text("Test")}, leftActionText: "", rightActionText: "", rightButtonAction: {}, height: 200,width: 270)
}
