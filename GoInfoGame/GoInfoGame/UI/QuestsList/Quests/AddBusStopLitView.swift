//
//  AddBusStopLitView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 12/01/24.
//

import SwiftUI

struct AddBusStopLitView: View {
    var body: some View {
        VStack{
            YesNoView()
        }.padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2))
       
    }
}

#Preview {
    AddBusStopLitView()
}
