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
    var contextualInfo: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
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
            Text(contextualInfo)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top,2)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    QuestionHeader(icon: Image("add_way_lit"), title: "Question", contextualInfo: "Description")
}
