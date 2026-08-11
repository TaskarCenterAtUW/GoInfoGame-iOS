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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // Title/close button are pinned outside the List so dismiss stays reachable without
        // scrolling. Everything else lives inside one continuous List (with sections), so
        // it all scrolls together in natural reading order — FEATURES, its toggles, HIDDEN
        // ELEMENTS, its instructions, then its rows — instead of the previous custom
        // VStack/ScrollView/List mix, where the hidden-elements list scrolled independently
        // of the content above it and could show its rows before their own section header
        // had even scrolled into view.
        VStack(spacing: 0) {
            header

            List {
                Section {
                    Text("Show all hidden elements on the map by individual item or type")
                        .font(FontFamily.Lato.bold.swiftUIFont(size: 12, relativeTo: .subheadline))
                        .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                        .multilineTextAlignment(.leading)
                        .accessibilityLabel("Show all hidden elements on the map by individual item or type")
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Section {
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
                    }
                } header: {
                    Text("FEATURES")
                        .font(.custom("Lato-Bold", size: 15, relativeTo: .headline))
                        .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                        .accessibilityLabel("Features")
                        .accessibilityAddTraits(.isHeader)
                }

                if !hiddenQuestManager.hiddenQuests.isEmpty {
                    Section {
                        ForEach(hiddenQuestManager.hiddenQuests.indices, id: \.self) { index in
                            let quest = hiddenQuestManager.hiddenQuests[index]
                            let idText = Text("ID: \(String(quest.id))")
                                .font(.custom("Lato-Bold", size: 15, relativeTo: .headline))
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityLabel("ID: \(String(quest.id))")
                            let nameText = Text(quest.name)
                                .font(.custom("Lato-Bold", size: 13, relativeTo: .body))
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityLabel(quest.name)

                            // Side by side, neither text has enough width at large
                            // accessibility text sizes to fit even a single whole word.
                            Group {
                                if dynamicTypeSize.isAccessibilitySize {
                                    VStack(alignment: .leading, spacing: 4) {
                                        idText
                                        nameText
                                    }
                                } else {
                                    HStack {
                                        idText
                                        Spacer()
                                        nameText
                                    }
                                }
                            }
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(quest.name), ID: \(quest.id)")
                        }
                        .onDelete { indexSet in
                            hiddenQuestManager.removeQuest(atOffsets: indexSet)
                        }
                    } header: {
                        hiddenElementsSectionHeader
                    } footer: {
                        Text("Swipe left on item to show delete option and delete it from the list.")
                            .font(.custom("Lato-Bold", size: 12, relativeTo: .subheadline))
                            .multilineTextAlignment(.leading)
                            .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                            .accessibilityLabel("Swipe left on item to show delete option and delete it from the list.")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .background(Color(red: 248 / 255, green: 248 / 255, blue: 248 / 255))
        .presentationDetents([.fraction(0.85), .large])
        .onDisappear {
            QuestsPublisher.shared.refreshQuest.send("")
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Choose which features to survey")
                .font(FontFamily.Lato.bold.swiftUIFont(size: 20, relativeTo: .headline))
                .fixedSize(horizontal: false, vertical: true) // Prevents the "unsupported" warning
                .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                .multilineTextAlignment(.leading)
                .accessibilityLabel("Choose which features to survey")

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
        .padding(.top, 30)
        .padding(.bottom, 10)
    }

    private var hiddenElementsSectionHeader: some View {
        // Side by side, both "HIDDEN ELEMENTS" and "Unhide All" have to share the row's
        // width; at large accessibility text each needs more than that, so neither has
        // room for even a single whole word and both wrap mid-word. Stacking them instead
        // gives each the full row width to wrap normally.
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    hiddenElementsLabel
                    unhideAllButton
                }
            } else {
                HStack(alignment: .firstTextBaseline) {
                    hiddenElementsLabel
                    Spacer()
                    unhideAllButton
                }
            }
        }
    }

    private var hiddenElementsLabel: some View {
        Text("HIDDEN ELEMENTS")
            .font(.custom("Lato-Bold", size: 15, relativeTo: .headline))
            .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("Hidden Elements")
            .accessibilityAddTraits(.isHeader)
    }

    private var unhideAllButton: some View {
        Button(action: {
            hiddenQuestManager.removeAllHiddenQuests()
        }) {
            Text("Unhide All")
                .font(.custom("Lato-Bold", size: 16, relativeTo: .headline))
                .foregroundColor(.white)
                .padding(.vertical, 10) // vertical padding
                .padding(.horizontal, 20) // horizontal padding
                .frame(minHeight: 44)
                .background(Asset.Colors.huskyPurple.swiftUIColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .cornerRadius(10)
                .accessibilityLabel("Unhide All")
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
