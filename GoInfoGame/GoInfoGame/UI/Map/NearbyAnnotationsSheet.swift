//
//  NearbyAnnotationsSheet.swift
//  GoInfoGame
//
//  Created on 06/12/26.
//

import SwiftUI
import MapKit

struct NearbyAnnotationsSheet: View {
    @Binding var isPresented: Bool
    @Binding var annotations: [DisplayUnitAnnotation]
    var onSelect: (DisplayUnitAnnotation) -> Void
    
    var body: some View {
        NavigationView {
            List(annotations, id: \.id) { annotation in
                Button(action: {
                    onSelect(annotation)
                    isPresented = false
                }) {
                    HStack(alignment: .center, spacing: 12) {
                        // Icon
                        if let iconName = annotation.displayUnit?.parent?.iconName {
                            Image(iconName)
                                .resizable()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        } else {
                            Image(systemName: "mappin.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.purple)
                        }
                        
                        if let quest = annotation.displayUnit?.parent as? LongElementQuest {
                            Text(quest.elementType)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// Preview
#Preview {
    NearbyAnnotationsSheet(
        isPresented: .constant(true),
        annotations: .constant([]),
        onSelect: { _ in }
    )
}
