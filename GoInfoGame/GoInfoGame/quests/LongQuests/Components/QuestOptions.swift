//
//  ShortAnswersWithoutImage.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 31/07/24.
//

import SwiftUI

struct QuestOptions: View {
    
    let options: [QuestAnswerChoice]
    
    @Binding var selectedChoice: QuestAnswerChoice?
    
    var questType: QuestType
    
    var uploadPhoto: (Bool) -> ()
    
    var body: some View {
        switch questType {
        case .exclusiveChoice:
            ExclusiveChoiceView(
                options: options,
                selectedChoice: $selectedChoice,
                uploadPhoto: uploadPhoto
            )
        case .multipleChoice:
            MultipleChoiceView(
                options: options,
                selectedChoice: $selectedChoice
            )
            
        case .numeric:
            NumericInputView(
                selectedChoice: $selectedChoice
            )
        case .textEntry:
            TextEntryView(
                selectedChoice: $selectedChoice
            )
        }
    }
}

// MARK: - Helper Views
private extension QuestOptions {

    struct ExclusiveChoiceView: View {
        let options: [QuestAnswerChoice]
        @Binding var selectedChoice: QuestAnswerChoice?
        var uploadPhoto: (Bool) -> ()

        @State private var selectedImageURL: String? = nil
        @State private var selectedImageText: String? = nil

        private let columns = [
            GridItem(.flexible(minimum: 10.0, maximum: 100.0), spacing: 30),
            GridItem(.flexible(minimum: 10.0, maximum: 100.0), spacing: 30),
            GridItem(.flexible(minimum: 10.0, maximum: 100.0), spacing: 30),
        ]

        var body: some View {
            ZStack {
                ScrollView {
                    if let imageUrl = selectedImageURL {
                        ExpandedImageView(
                            imageUrl: imageUrl,
                            imageText: selectedImageText,
                            onClose: {
                                selectedImageURL = nil
                                selectedImageText = nil
                            }
                        )
                        .transition(.scale)
                        .animation(.easeInOut, value: selectedImageURL)
                    }

                    VStack(spacing: 16) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(options, id: \.id) { option in
                                OptionButton(
                                    option: option,
                                    selectedChoice: $selectedChoice,
                                    onLongPress: {
                                        if let imageUrl = option.imageURL, !imageUrl.isEmpty {
                                            selectedImageURL = imageUrl
                                            selectedImageText = option.choiceText
                                        }
                                    }
                                )
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel((selectedChoice?.choiceText == option.choiceText) ? "\(option.choiceText) \(L10n.Localizable.optionSelected)" :  "\(option.choiceText) \(L10n.Localizable.optionUnselected)")
                            }
                        }

                        FollowUpButton(
                            options: options,
                            selectedChoice: $selectedChoice,
                            uploadPhoto: uploadPhoto
                        )
                    }
                    .padding()
                }
            }
        }
    }

    struct MultipleChoiceView: View {
        let options: [QuestAnswerChoice]
        @Binding var selectedChoice: QuestAnswerChoice?

        @State private var selectedValues: Set<String> = []
        @State private var selectedImageURL: String? = nil
        @State private var selectedImageText: String? = nil

        private let columns = [
            GridItem(.flexible(minimum: 10.0, maximum: 100.0), spacing: 30),
            GridItem(.flexible(minimum: 10.0, maximum: 100.0), spacing: 30),
            GridItem(.flexible(minimum: 10.0, maximum: 100.0), spacing: 30),
        ]

        var body: some View {
            ZStack {
                ScrollView {
                    if let imageUrl = selectedImageURL {
                        ExpandedImageView(
                            imageUrl: imageUrl,
                            imageText: selectedImageText,
                            onClose: {
                                selectedImageURL = nil
                                selectedImageText = nil
                            }
                        )
                        .transition(.scale)
                        .animation(.easeInOut, value: selectedImageURL)
                    }

                    VStack(spacing: 16) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(options, id: \.id) { option in
                                MultiSelectOptionButton(
                                    option: option,
                                    isSelected: selectedValues.contains(option.value),
                                    onTap: {
                                        toggleSelection(for: option)
                                    },
                                    onLongPress: {
                                        if let imageUrl = option.imageURL, !imageUrl.isEmpty {
                                            selectedImageURL = imageUrl
                                            selectedImageText = option.choiceText
                                        }
                                    }
                                )
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel((selectedValues.contains(option.value)) ? "\(option.choiceText) \(L10n.Localizable.optionSelected)" :  "\(option.choiceText) \(L10n.Localizable.optionUnselected)")
                            }
                        }
                    }
                    .padding()
                }
            }
            .onAppear(perform: initializeSelectedValues)
            .onChange(of: selectedValues) { _ in
                updateSelectedChoice()
            }
            .onChange(of: selectedChoice) { _ in
                initializeSelectedValues()
            }
        }

        private func initializeSelectedValues() {
            let currentSelectedValues = Set((selectedChoice?.value ?? "").components(separatedBy: ";").filter { !$0.isEmpty })
            if selectedValues != currentSelectedValues {
                selectedValues = currentSelectedValues
            }
        }

        private func toggleSelection(for option: QuestAnswerChoice) {
            if selectedValues.contains(option.value) {
                selectedValues.remove(option.value)
            } else {
                selectedValues.insert(option.value)
            }
        }

        private func updateSelectedChoice() {
            let combinedValue = selectedValues.sorted().joined(separator: ";")

            if combinedValue.isEmpty {
                if selectedChoice != nil {
                    selectedChoice = nil
                }
            } else {
                if selectedChoice?.value != combinedValue {
                    let fakeAnswer = QuestAnswerChoice(value: combinedValue, choiceText: combinedValue, imageURL: nil, choiceFollowUp: nil)
                    selectedChoice = fakeAnswer
                }
            }
        }
    }

    struct NumericInputView: View {
        @Binding var selectedChoice: QuestAnswerChoice?

        var body: some View {
            HStack {
                TextField("Enter value", text: Binding(
                    get: { selectedChoice?.value ?? "" },
                    set: { newValue in
                        if newValue.isEmpty {
                            selectedChoice = nil
                        } else {
                            if selectedChoice?.value != newValue {
                                let answer = QuestAnswerChoice(value: newValue, choiceText: newValue, imageURL: nil, choiceFollowUp: nil)
                                selectedChoice = answer
                            }
                        }
                    }
                ))
                .frame(width: 100)
                .padding(1)
                .textFieldStyle(PlainTextFieldStyle())
                .keyboardType(UIKeyboardType.numberPad)
            }
        }
    }
    
    struct TextEntryView: View {
        @Binding var selectedChoice: QuestAnswerChoice?
        let maxLenth: Int = 255
        
        private var currentValue: String {
            selectedChoice?.value ?? ""
        }
        
        var body: some View {
            ZStack(alignment: .bottomTrailing) {
                TextEditor(text: Binding(
                    get: { selectedChoice?.value ?? "" },
                    set: { newValue in
                        let truncatedValue = String(newValue.prefix(maxLenth))
                        if truncatedValue.isEmpty {
                            selectedChoice = nil
                        } else {
                            let answer = QuestAnswerChoice(value: truncatedValue, choiceText: truncatedValue, imageURL: nil, choiceFollowUp: nil)
                            selectedChoice = answer
                        }
                    }
                ))
                .frame(height: 100)
                .keyboardType(UIKeyboardType.default)
                .border(Color.gray)
                
                Text("\(currentValue.count) / \(maxLenth)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(5)
                    .background(Color.white.opacity(0.5))
            }
        }
    }

    struct ExpandedImageView: View {
        let imageUrl: String
        let imageText: String?
        let onClose: () -> Void

        var body: some View {
            VStack {
                LongFormImageView(
                    urlString: imageUrl,
                    width: 300,
                    height: 300
                )

                if let text = imageText {
                    StrokedText(text: text)
                }

                Spacer()

                Button("Close") {
                    onClose()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
        }
    }

    struct OptionButton: View {
        let option: QuestAnswerChoice
        @Binding var selectedChoice: QuestAnswerChoice?
        let onLongPress: () -> Void

        var body: some View {
            Button(action: {
                if selectedChoice == option {
                    // Deselect
                    selectedChoice = nil
                } else {
                    // Select
                    selectedChoice = option
                }
            }) {
                VStack(spacing: 8) {
                    if let imageUrl = option.imageURL, !imageUrl.isEmpty {
                        LongFormImageView(
                            urlString: imageUrl,
                            width: 100,
                            height: 100,
                            label: option.choiceText
                        )
                    } else {
                        NoImageView(text: option.choiceText)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedChoice == option ? Asset.Colors.accentPink.swiftUIColor : Color.clear, lineWidth: 3)
            )
            .onLongPressGesture(perform: onLongPress)
        }
    }

    struct MultiSelectOptionButton: View {
        let option: QuestAnswerChoice
        let isSelected: Bool
        let onTap: () -> Void
        let onLongPress: () -> Void

        var body: some View {
            Button(action: onTap) {
                VStack(spacing: 8) {
                    if let imageUrl = option.imageURL, !imageUrl.isEmpty {
                        LongFormImageView(
                            urlString: imageUrl,
                            width: 100,
                            height: 100,
                            label: option.choiceText
                        )
                    } else {
                        NoImageView(text: option.choiceText)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Asset.Colors.accentPink.swiftUIColor : Color.clear, lineWidth: 3)
            )
            .onLongPressGesture(perform: onLongPress)
        }
    }


    struct NoImageView: View {
        let text: String

        var body: some View {
            ZStack {
                Text(text)
                    .foregroundStyle(Color.black)
                    .frame(width: 100, height: 100)
                    .minimumScaleFactor(0.67)
                    .bold()
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    }
            }
            .accessibilityHidden(true)
        }
    }

    struct FollowUpButton: View {
        let options: [QuestAnswerChoice]
        @Binding var selectedChoice: QuestAnswerChoice?
        let uploadPhoto: (Bool) -> Void

        var body: some View {
            if let selected = selectedChoice, selected.choiceFollowUp != nil {
                Button(action: {
                    uploadPhoto(true)
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "camera")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)

                        Text(selected.choiceFollowUp ?? "Upload a picture")
                            .font(.custom("Lato-Regular", size: 13))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Asset.Colors.huskyPurple.swiftUIColor, Asset.Colors.accentPink.swiftUIColor]), startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(color: Color.gray.opacity(0.5), radius: 4, x: 2, y: 2)
                    .cornerRadius(9)
                }
            }
        }
    }

    struct StrokedText: View {
        let text: String

        var body: some View {
            ZStack {
                let strokeOffsets: [(CGFloat, CGFloat)] = [
                    (-1, -1), (1, -1),
                    (-1, 1), (1, 1),
                    (0, -1), (0, 1),
                    (-1, 0), (1, 0)
                ]

                ForEach(0..<strokeOffsets.count, id: \.self) { i in
                    let offset = strokeOffsets[i]
                    Text(text)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                        .offset(x: offset.0, y: offset.1)
                }

                Text(text)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.7), radius: 4, x: 0, y: 2)
            }
        }
    }
}

#Preview {
    QuestOptions(options: [QuestAnswerChoice(value: "asphalt", choiceText: "Asphalt", imageURL: "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/refs/heads/main/images/sidewalk/surface/asphalt_landscape.png", choiceFollowUp: nil),
                           QuestAnswerChoice(value: "no", choiceText: "No, this roadway is too wide to cross safely.", imageURL: nil, choiceFollowUp: nil)],
                 selectedChoice: .constant(QuestAnswerChoice(value: "no", choiceText: "No, this roadway is too wide to cross safely.", imageURL: nil, choiceFollowUp: nil)),
                 questType: GoInfoGame.QuestType.exclusiveChoice) { s in
        
    }
}
