//
//  QuestsListUIView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 04/01/24.
//

import SwiftUI
extension String: Identifiable {
    public var id: String { return self }
}
struct QuestsListUIView: View {
    @State private var selectedText: String?
    let questTitles = ["Determine sidewalk widths","Determine number of stairs","Determine flights of stairs","Specify whether ways are lit","Specify whether bus stop is lit","Specify whether crossing is marked or unmarked and what the marking references are","Specify signalization of this crossing","Specify surface type of sidewalk","Specify whether this sidewalk actually exists.","Specify whether this corner has kerb ramps","Specify whether public transport stops have shelters","Specify whether public transport stops have benches","Add whether public transport stops have a Braille schedule board"]
    var body: some View {
        List{
            if #available(iOS 15.0, *) {
                Section("Questions List"){
                    ForEach(questTitles, id: \.self) { text in
                        Button(action: {
                            // Handle the click action for each text element
                            selectedText = text
                            print("Clicked: \(text)")
                        }) {
                            Text(text)
                        }
                    }
                }
            } else {
                // Fallback on earlier versions
                Text("Questions List")
            }
        }.sheet(item: $selectedText) { selectedText in
            if #available(iOS 16.0, *) {
                VStack {
                    Text(selectedText)
                }
                .presentationDetents([.medium, .large])
            }
            else{
                VStack {
                    Text(selectedText)
                }
            }
        }
    }
}

#Preview {
    QuestsListUIView()
}
