//
//  UserSettingsView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar Maddela on 17/03/25.
//

import SwiftUI
    
import SwiftUI

struct OptionModel: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let icon: String
    let destination: SettingsDestination
    
    static let options: [OptionModel] = [
           OptionModel(title: "User Profile", icon: "person.crop.circle.fill", destination: .profile),
           OptionModel(title: "Manage Quests", icon: "slider.horizontal.3", destination: .manageQuests),
           OptionModel(title: "Download Data", icon: "arrow.down.circle.fill", destination: .downloadData)
       ]
}

enum SettingsDestination: Hashable {
    case profile
    case manageQuests
    case downloadData

}
struct UserSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
   
    
    let options: [OptionModel]
    let onNavigate: (SettingsDestination) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("")


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
            .padding(.top, 15)

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
                                .padding(.leading, 8)

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onNavigate(option.destination)
                        }

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
