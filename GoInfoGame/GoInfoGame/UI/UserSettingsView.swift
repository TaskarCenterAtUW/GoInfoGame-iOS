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
           OptionModel(title: "Switch Workspace", icon: "arrow.right.arrow.left.circle.fill", destination: .switchWorkspace)
       ]
}

enum SettingsDestination: Hashable {
    case profile
    case manageQuests
    case switchWorkspace

}
struct UserSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
   
    @State var selectedWorkspace: String = ""
    let options: [OptionModel]
    let onNavigate: (SettingsDestination) -> Void

    var body: some View {
        // Content-sized as long as everything fits; falls back to a scrolling options
        // list only if it doesn't (many options, or very large accessibility text).
        // `.sizedToFitContent()` measures whichever of the two this actually renders.
        ViewThatFits(in: .vertical) {
            settingsContent(scrollable: false)
            settingsContent(scrollable: true)
        }
        .sizedToFitContent()
    }

    private func settingsContent(scrollable: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if scrollable {
                ScrollView { optionsList }
            } else {
                optionsList
            }

            Spacer()
        }
        .padding(.bottom, 16)
        .background(Color(red: 248/255, green: 248/255, blue: 248/255))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(selectedWorkspace)
                .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .minimumScaleFactor(0.5) // safety net for workspace names with no space to wrap on
                .accessibilityLabel(selectedWorkspace)

            Spacer()

            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Image(systemName: "xmark.circle")
                    .resizable()
                    .frame(width: 25, height: 25)
                    .foregroundStyle(Asset.Colors.accentPink.swiftUIColor)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            })
        }
        .padding(.horizontal, 16)
        .padding([.bottom, .top], 10)
    }

    private var optionsList: some View {
        VStack(spacing: 0) {
            ForEach(options, id: \.title) { option in
                HStack {
                    Image(systemName: option.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)

                    Text(option.title)
                        .font(.custom("Lato-Bold", size: 16, relativeTo: .headline))
                        .foregroundColor(Color(red: 69/255, green: 81/255, blue: 108/255))
                        .padding(.leading, 8)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .accessibilityLabel(option.title)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 50)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    onNavigate(option.destination)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(option.title)

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
}

#Preview {
    UserSettingsView( selectedWorkspace: "Title", options: OptionModel.options) { _ in
        
    }
}
