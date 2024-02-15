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
    let isLabelBelow: Bool
    let imageData: [ImageData]
    let isImageRotated: Bool
    let isDisplayImageOnly: Bool
    let isScrollable: Bool
    let allowMultipleSelection: Bool // Boolean indicating whether multiple image selection is allowed
    let onTap: ([String]) -> Void
    
    @Binding var selectedImages: [String]
    
    var body: some View {
        // Conditionally choose between ScrollView and LazyVGrid based on isScrollable
        if isScrollable {
            ScrollView {
                gridWithSpacing( gridCount == 2 ? 5 : 0, count: gridCount, content: imageData)
            }
        } else {
            gridWithSpacing( gridCount == 2 ? 5 : 0, count: gridCount, content: imageData)
        }
    }
    // Function to create LazyVGrid with custom spacing and content
    func gridWithSpacing(_ spacing: CGFloat, count: Int, content: [ImageData]) -> some View {
        return LazyVGrid(columns: Array(repeating: GridItem(spacing: spacing), count: count), spacing: spacing) {
            ForEach(imageData) { data in
                VStack {
                    Button(action: {
                        // If multiple selection is allowed
                        if allowMultipleSelection {
                            /// If the image tag is "none"
                            if data.tag == "none" {
                                /// checking if selected tag already exists in selectedImages
                                if selectedImages.contains(data.tag){
                                    selectedImages.removeAll() /// Clear all selections
                                } else{
                                    selectedImages = ["none"] /// Select "none"
                                }
                                /// If the image tag is not "none"
                            } else {
                                if selectedImages.contains("none"){
                                    /// Remove "none" from selection
                                    selectedImages.removeObject(element: "none")
                                }
                                if selectedImages.contains(data.tag) {
                                    /// Deselect the image
                                    selectedImages.removeObject(element: data.tag)
                                } else {
                                    /// Select the image
                                    selectedImages.append(data.tag)
                                }
                            }
                        } else {
                            // Select the image if multiple selection is not allowed
                            selectedImages = [data.tag]
                        }
                        onTap(selectedImages)
                    })
                    {
                        ZStack {
                            Image(data.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(minWidth: isLabelBelow ? 70 : 0, maxWidth: isLabelBelow ? 70 : .infinity, minHeight: isLabelBelow ? 70 : 150, maxHeight: isLabelBelow ? 70 : 150)
                                .cornerRadius(10)
                                .clipped()
                                .rotationEffect(.degrees(isImageRotated ? 30: 0))
                                .border(selectedImages.contains(data.tag) ? Color.orange : Color.clear, width: selectedImages.contains(data.tag) ? 3 : 0)
                            if !isLabelBelow {
                                Text(data.optionName)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(20)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                            }
                        }
                        
                    }.disabled(isDisplayImageOnly)
                    if isLabelBelow {
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
