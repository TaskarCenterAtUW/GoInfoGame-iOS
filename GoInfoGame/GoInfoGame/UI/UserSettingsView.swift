//
//  UserSettingsView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar Maddela on 17/03/25.
//

import SwiftUI
    
import SwiftUI

struct UserSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var options: [(icon: String, title: String)] = [
        ("person.fill", "User Profile"),
        ("list.bullet", "Manage Quests"),
        ("arrow.right.square", "Logout")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("User Name")
                    .font(.custom("Lato-Bold", size: 19))
                    .foregroundColor(Color(red: 69/255, green: 81/255, blue: 108/255))
                    .padding(.top, 30)

                Spacer()

                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Image("long-form-dismiss")
                        .resizable()
                        .frame(width: 25, height: 25)
                })
            }
            .padding(.horizontal, 16)
            .padding(.bottom)

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    ForEach(options, id: \.title) { option in
                        HStack {
                            Image(systemName: option.icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(Color(red: 69/255, green: 81/255, blue: 108/255))
                            
                            Text(option.title)
                                .font(.custom("Lato-Bold", size: 16))
                                .foregroundColor(Color(red: 69/255, green: 81/255, blue: 108/255))

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 50) // Increased row height
                        
                        if option.title != options.last?.title {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding([.leading, .trailing], 22)
            }

            Spacer()
        }
        .padding(.bottom, 16)
        .background(Color(red: 248/255, green: 248/255, blue: 248/255))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}


struct UserSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        UserSettingsView()
    }
}
