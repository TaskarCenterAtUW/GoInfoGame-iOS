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
           OptionModel(title: "Download Data", icon: "arrow.down.circle.fill", destination: .downloadData),
           OptionModel(title: "Switch Workspace", icon: "arrow.right.arrow.left.circle.fill", destination: .switchWorkspace)
       ]
}

enum SettingsDestination: Hashable {
    case profile
    case manageQuests
    case downloadData
    case switchWorkspace

}
struct UserSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
   
    @State var selectedWorkspace: String = ""
    let options: [OptionModel]
    let onNavigate: (SettingsDestination) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(selectedWorkspace)
                    .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                    .lineLimit(1)


                Spacer()

                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Image(systemName: "xmark.circle")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .foregroundStyle(Asset.Colors.accentPink.swiftUIColor)
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
                                .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)

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

#Preview {
    UserSettingsView( selectedWorkspace: "Title", options: OptionModel.options) { _ in
        
    }
}
