//
//  ImageGridItemView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 12/01/24.
//

import SwiftUI

struct ImageData: Identifiable {
    var id: String?
    let type: String
    let imageName: String
    let tag: String
    let optionName: String
}
struct ImageGridItemView: View {
    let imageData: [ImageData]
    let onTap: (String, String) -> Void
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(), count: 2),spacing: 5) {
            ForEach(imageData) { data in
                VStack {
                    Button(action: {
                        onTap(data.type, data.tag)
                    }) {
                        ZStack(){
                            Image(data.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 150, maxHeight: 150)
                                .cornerRadius(10)
                                .clipped()
                            Text(data.optionName)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(20)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        }
                        
                    }
                }
            }
        }
    }
}



//#Preview {
//    ImageGridItemView()
//}
