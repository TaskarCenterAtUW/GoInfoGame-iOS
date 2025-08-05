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
                    .font(.custom("Lato-Bold", size: 20))
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

            Text("Show all hidden elements on the map by individual item or type")
                .font(.custom("Lato-Bold", size: 12))
                .foregroundColor(Color(red: 132/255, green: 135/255, blue: 153/255))
                .padding(.horizontal)

            Text("FEATURES")
                .font(.custom("Lato-Bold", size: 15))
                .foregroundColor(Color(red: 132/255, green: 135/255, blue: 153/255))
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.leading, 15)
            
            GeometryReader { geometry in
                VStack(spacing: 0) { // No extra spacing between rows
                    ForEach(questManager.longQuestModels.indices, id: \.self) { index in
                        let quest = questManager.allQuests[index]
                        let title = quest.quest.title.isEmpty ?
                                    (index < questManager.longQuestModels.count ? questManager.longQuestModels[index].elementType : "") :
                                    quest.quest.title

                        Toggle(isOn: $questManager.allQuests[index].isDefault) {
                            Text(title)
                                .font(.custom("Lato-Bold", size: 16))
                                .foregroundColor(Color(red: 69/255, green: 81/255, blue: 108/255))
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
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
            .frame(height: CGFloat(questManager.allQuests.count) * 50)


            if hiddenQuestManager.hiddenQuests.isEmpty {
                Color.clear.frame(height: 50) // Placeholder to prevent jumpy UI
            } else {
                HStack(alignment: .firstTextBaseline) {
                    Text("HIDDEN ELEMENTS")
                        .font(.custom("Lato-Bold", size: 15))
                        .foregroundColor(Color(red: 132/255, green: 135/255, blue: 153/255))
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.leading, 15)
                    Spacer()
                    Button(action: {
                        hiddenQuestManager.removeAllHiddenQuests()
                    }) {
                        Text("Unhide All")
                            .font(.custom("Lato-Bold", size: 16))
                            .foregroundColor(.white)
                            .padding(.vertical, 10) // vertical padding
                            .padding(.horizontal, 20) // horizontal padding
                            .background(Asset.Colors.huskyPurple.swiftUIColor)
                            .cornerRadius(10)
                    }
                    .padding(.trailing, 15)

                    
                }
                Text("Swipe left on item to show delete option and delete it from the list.")
                    .font(.custom("Lato-Bold", size: 12))
                    .foregroundColor(Color(red: 132/255, green: 135/255, blue: 153/255))
                    .padding(.horizontal)

                List {
                    ForEach(hiddenQuestManager.hiddenQuests.indices, id: \.self) { index in
                        let quest = hiddenQuestManager.hiddenQuests[index]

                        HStack {
                            Text("ID: \(String(quest.id))")
                                .font(.custom("Lato-Bold", size: 15))
                                .foregroundColor(Color(red: 69 / 255, green: 81 / 255, blue: 108 / 255))
                        
                            Spacer()
                            Text(quest.name)
                                .font(.custom("Lato-Bold", size: 13))
                                .foregroundColor(.gray)
                                
                        }
                       
                        .listRowInsets(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
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
