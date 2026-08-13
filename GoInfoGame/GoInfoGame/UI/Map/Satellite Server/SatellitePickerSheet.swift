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
                    let isSelected = option == selected
                    Button {
                        onSelect(option)
                    } label: {
                        HStack {
                            Text(option.name)
                                .font(FontFamily.Lato.regular.swiftUIFont(size: 14, relativeTo: .body))
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Asset.Colors.accentPink.swiftUIColor)
                                    .accessibilityHidden(true)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    // Inside a List row — without this, List applies its own default
                    // button/selection styling on top of ours.
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.name)
                    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
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
