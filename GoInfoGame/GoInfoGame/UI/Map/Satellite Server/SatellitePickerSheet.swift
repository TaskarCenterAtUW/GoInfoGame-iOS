//
//  Sat.swift
//  GoInfoGame
//
//  Created by Prashamsa on 30/06/25.
//

import SwiftUI

struct SatellitePickerSheet: View {
    @Binding var options: [SatelliteOption]
    @Binding var selected: SatelliteOption
    var onSelect: (SatelliteOption) -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(options, id: \.self) { option in
                    HStack {
                        Text(option.name)
                            .font(FontFamily.Lato.regular.swiftUIFont(size: 14, relativeTo: .body))
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .accessibilityLabel(option.name)
                        Spacer()
                        if option == selected {
                            Image(systemName: "checkmark")
                                .foregroundColor(Asset.Colors.accentPink.swiftUIColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(option)
                    }
                }
            }
            .navigationTitle("Select Satellite Layer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Select Satellite Layer")
                        .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                        .font(FontFamily.Lato.regular.swiftUIFont(size: 14, relativeTo: .body))
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .accessibilityLabel("Select Satellite Layer")
                }
            }
        }
    }
}
