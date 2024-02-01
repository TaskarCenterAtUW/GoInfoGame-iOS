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
    let gridCount: Int
    let isLabelBelow : Bool
    let imageData: [ImageData]
    let isImageRotated: Bool
    let isDisplayImageOnly : Bool
    let onTap: (String, String) -> Void
    
    @State private var selectedImage: String?
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(spacing: gridCount == 2 ? 5 : 0), count: gridCount),spacing:  gridCount == 2 ? 5 : 0) {
            ForEach(imageData) { data in
                VStack {
                    Button(action: {
                        onTap(data.type, data.tag)
                        selectedImage = data.imageName
                    }) {
                        ZStack(){
                            Image(data.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(minWidth: isLabelBelow ? 70 : 0, maxWidth: isLabelBelow ? 70 : .infinity, minHeight:isLabelBelow ? 70 : 150, maxHeight: isLabelBelow ? 70 : 150)
                                .cornerRadius(10)
                                .clipped()
                                .rotationEffect(.degrees(isImageRotated ? 30: 0))
                                .border(selectedImage == data.imageName ? Color.orange : Color.clear, width: selectedImage == data.imageName ? 3 : 0)
                            if !isLabelBelow{
                                Text(data.optionName)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(20)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                            }
                        }
                        
                    }.disabled(isDisplayImageOnly)
                    if isLabelBelow{
                        Text(data.optionName)
                            .font(.caption)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
}



//#Preview {
//    ImageGridItemView()
//}
