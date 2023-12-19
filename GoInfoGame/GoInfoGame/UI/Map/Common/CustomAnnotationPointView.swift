//
//  CustomAnnotationPointView.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 19/12/23.
//

import SwiftUI

struct CustomAnnotationPointView: View {
    
    var dynamicImage: UIImage?
    
    var body: some View {
           Image("mapPoint")
               .resizable()
               .aspectRatio(contentMode: .fit)
               .frame(width: 48, height: 48)
               .overlay(
                   Group {
                       if let dynamicImage = dynamicImage {
                           Image(uiImage: dynamicImage)
                               .resizable()
                               .aspectRatio(contentMode: .fit)
                               .frame(width: 24, height: 24)
                               .offset(y: -10)
                       }
                   }
               )
       }
}

#Preview {
    CustomAnnotationPointView()
}
