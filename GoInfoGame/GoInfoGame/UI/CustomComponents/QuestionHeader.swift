//
//  QuestionHeader.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/17/24.
//

import SwiftUI

struct QuestionHeader: View {
    var icon: Image
    var title: String
    var subtitle: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .frame(alignment: Alignment.center).padding(.top,20)
                Spacer()
            }
            Text(title)
                .font(.headline)
                .padding(.top, 10)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top,2)
        }
    }
}

#Preview {
    QuestionHeader(icon: Image("add_way_lit"), title: "Question", subtitle: "Description")
}
