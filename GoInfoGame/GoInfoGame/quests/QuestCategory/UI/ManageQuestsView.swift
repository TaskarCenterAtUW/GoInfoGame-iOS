//
// ManageQuestsView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 16/01/25.
//

import SwiftUI

struct ManageQuestsView: View {
    @ObservedObject var questManager = QuestsRepository.shared
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var hiddenQuestManager = HiddenQuestManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Choose which features to survey")
                    .font(FontFamily.Lato.bold.swiftUIFont(size: 20, relativeTo: .headline))
                    .fixedSize(horizontal: false, vertical: true) // Prevents the "unsupported" warning
                    .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 30)
                    .accessibilityLabel("Choose which features to survey")

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

            Text("Show all hidden elements on the map by individual item or type")
                .font(FontFamily.Lato.bold.swiftUIFont(size: 12, relativeTo: .subheadline))
                .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
                .accessibilityLabel("Show all hidden elements on the map by individual item or type")

            Text("FEATURES")
                .font(.custom("Lato-Bold", size: 15, relativeTo: .headline))
                .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.leading, 15)
                .accessibilityLabel("Features")
            
            ScrollView {
                VStack(spacing: 0) { // No extra spacing between rows
                    ForEach(questManager.longQuestModels.indices, id: \.self) { index in
                        let quest = questManager.allQuests[index]
                        let title = quest.quest.title.isEmpty ?
                                    (index < questManager.longQuestModels.count ? questManager.longQuestModels[index].elementType : "") :
                                    quest.quest.title

                        Toggle(isOn: $questManager.allQuests[index].isDefault) {
                            Text(title)
                                .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                                .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)
                                .accessibilityLabel(title)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: Asset.Colors.accentPink.swiftUIColor))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)

                        if index != questManager.allQuests.count - 1 {
                            Divider().padding(.leading, 10)
                        }
                    }

                }
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding([.leading, .trailing], 22)
            }
            .frame(minHeight: CGFloat(questManager.allQuests.count) * 60)


            if hiddenQuestManager.hiddenQuests.isEmpty {
                Color.clear.frame(height: 50) // Placeholder to prevent jumpy UI
            } else {
                HStack(alignment: .firstTextBaseline) {
                    Text("HIDDEN ELEMENTS")
                        .font(.custom("Lato-Bold", size: 15, relativeTo: .headline))
                        .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .accessibilityLabel("Hidden Elements")
                    Spacer()
                    Button(action: {
                        hiddenQuestManager.removeAllHiddenQuests()
                    }) {
                        Text("Unhide All")
                            .font(.custom("Lato-Bold", size: 16, relativeTo: .headline))
                            .foregroundColor(.white)
                            .padding(.vertical, 10) // vertical padding
                            .padding(.horizontal, 20) // horizontal padding
                            .background(Asset.Colors.huskyPurple.swiftUIColor)
                            .multilineTextAlignment(.leading)
                            .cornerRadius(10)
                            .accessibilityLabel("Unhide All")
                    }
                    .padding(.trailing, 15)

                    
                }
                Text("Swipe left on item to show delete option and delete it from the list.")
                    .font(.custom("Lato-Bold", size: 12, relativeTo: .subheadline))
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                    .padding(.horizontal)
                    .accessibilityLabel("Swipe left on item to show delete option and delete it from the list.")

                List {
                    ForEach(hiddenQuestManager.hiddenQuests.indices, id: \.self) { index in
                        let quest = hiddenQuestManager.hiddenQuests[index]

                        HStack {
                            Text("ID: \(String(quest.id))")
                                .font(.custom("Lato-Bold", size: 15, relativeTo: .headline))
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityLabel("ID: \(String(quest.id))")
                            Spacer()
                            
                            Text(quest.name)
                                .font(.custom("Lato-Bold", size: 13, relativeTo: .body))
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityLabel(quest.name)
                        }
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .accessibilityElement(children: .combine)
                        .listRowInsets(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
                        .accessibilityLabel("\(quest.name), ID: \(quest.id)")
                    }
                    .onDelete { indexSet in
                        hiddenQuestManager.removeQuest(atOffsets: indexSet)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 22)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top) // Keep Manage Quests at the top
        .padding(.bottom, 16)
        .background(Color(red: 248 / 255, green: 248 / 255, blue: 248 / 255))
        .onDisappear {
            QuestsPublisher.shared.refreshQuest.send("")
        }
    }

}

struct CheckBoxView: View {
    
    let isChecked: Bool;
    
    var body: some View {
        Image(systemName: isChecked ? "checkmark.square.fill" : "square")
            .foregroundColor(isChecked ? Color(UIColor.systemBlue) : Color.secondary)
    }
}

//preview for QuestCategoryListView
struct ManageQuestsView_Previews: PreviewProvider {
    static var previews: some View {
        ManageQuestsView()
        
    }
}
