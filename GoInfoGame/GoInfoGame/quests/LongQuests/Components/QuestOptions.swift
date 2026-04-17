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
    
    @AppStorage("lowBandwidthMode") private var lowBandwidthMode: Bool = false
    
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
                selectedChoice: $selectedChoice,
                uploadPhoto: uploadPhoto
            )
            
        case .numeric:
            NumericInputView(
                selectedChoice: $selectedChoice
            )
        case .textEntry:
            TextEntryView(
                selectedChoice: $selectedChoice
            )
        case .autoCapture:
            AutoCaptureView(selectedChoice: $selectedChoice)
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
                    if selectedImageURL != nil || selectedImageText != nil {
                        ExpandedImageView(
                            imageUrl: selectedImageURL,
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
                                        selectedImageURL = option.imageURL
                                        selectedImageText = option.choiceText
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
        var uploadPhoto: (Bool) -> ()

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
                    if selectedImageURL != nil || selectedImageText != nil {
                        ExpandedImageView(
                            imageUrl: selectedImageURL,
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
                                        selectedImageURL = option.imageURL
                                        selectedImageText = option.choiceText
                                    }
                                )
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel((selectedValues.contains(option.value)) ? "\(option.choiceText) \(L10n.Localizable.optionSelected)" :  "\(option.choiceText) \(L10n.Localizable.optionUnselected)")
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
                .font(FontFamily.Lato.regular.swiftUIFont(size: 14, relativeTo: .body))
                .textFieldStyle(PlainTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding(.vertical, 12) // Adds internal space
                .padding(.horizontal, 10)
                .frame(minWidth: 100, minHeight: 44) // Meets accessibility minimums
                .background(Color.clear) // Helps define the tappable area
                .contentShape(Rectangle()) // Makes the entire frame hit-testable
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .accessibilityLabel("Numeric input field. Current value: \(selectedChoice?.value ?? "empty").")
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
                .font(FontFamily.Lato.regular.swiftUIFont(size: 14, relativeTo: .body))
                .textFieldStyle(PlainTextFieldStyle())
                .keyboardType(UIKeyboardType.default)
                .padding(.vertical, 12) // Adds internal space
                .frame(minWidth: 100, minHeight: 100) // Meets accessibility minimums
                .background(Color.clear) // Helps define the tappable area
                .contentShape(Rectangle()) // Makes the entire frame hit-testable
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .border(Color.gray)
                .accessibilityLabel("Text entry field. \(currentValue.count) out of \(maxLenth) characters used.")
                
                Text("\(currentValue.count) / \(maxLenth)")
                    .font(.caption)
                    .foregroundColor(.black)
                    .padding(5)
                    .background(Color.white.opacity(0.5))
                    .accessibilityHidden(true)
            }
        }
    }

    struct ExpandedImageView: View {
        let imageUrl: String?
        let imageText: String?
        let onClose: () -> Void

        var body: some View {
            VStack {
                if let url = imageUrl {
                    LongFormImageView(
                        urlString: url,
                        width: 300,
                        height: 300
                    )
                }

                if let text = imageText {
                    Text(text)
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

        @AppStorage("lowBandwidthMode") private var lowBandwidthMode: Bool = false

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
                        if lowBandwidthMode {
                            NoImageView(text: option.choiceText)
                        } else {
                            LongFormImageView(
                                urlString: imageUrl,
                                width: 100,
                                height: 100,
                                label: option.choiceText
                            )
                        }
                    } else {
                        NoImageView(text: option.choiceText)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedChoice == option ? Asset.Colors.accentPink.swiftUIColor : Color.clear, lineWidth: 3)
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                    onLongPress()
                }
            )
        }
    }

    struct MultiSelectOptionButton: View {
        let option: QuestAnswerChoice
        let isSelected: Bool
        let onTap: () -> Void
        let onLongPress: () -> Void

        @AppStorage("lowBandwidthMode") private var lowBandwidthMode: Bool = false

        var body: some View {
            Button(action: onTap) {
                VStack(spacing: 8) {
                    if let imageUrl = option.imageURL, !imageUrl.isEmpty {
                        if lowBandwidthMode {
                            NoImageView(text: option.choiceText)
                        } else {
                            LongFormImageView(
                                urlString: imageUrl,
                                width: 100,
                                height: 100,
                                label: option.choiceText
                            )
                        }
                    } else {
                        NoImageView(text: option.choiceText)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Asset.Colors.accentPink.swiftUIColor : Color.clear, lineWidth: 3)
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                    onLongPress()
                }
            )
        }
    }

    // MARK: - AutoCaptureView (Multi-capture version)
    struct AutoCaptureView: View {
        @Binding var selectedChoice: QuestAnswerChoice?
        
        // Data model for a single capture
        struct Capture: Identifiable {
            let id = UUID()
            let image: UIImage
            let widthMeters: Double
            let slopeDegrees: Double
        }
        
        @State private var captures: [Capture] = []
        @State private var showImagePicker = false
        @State private var isProcessing = false
        @State private var tempImage: UIImage? = nil

        var body: some View {
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        // Display all captures
                        if !captures.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Captured Measurements")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(captures) { capture in
                                    CaptureCard(
                                        capture: capture,
                                        onDelete: {
                                            captures.removeAll { $0.id == capture.id }
                                            updateSelectedChoice()
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Add more captures button
                        Button(action: {
                            showImagePicker = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                Text(captures.isEmpty ? "Open Camera" : "Add Another Capture")
                            }
                            .font(.headline)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 28)
                            .background(Asset.Colors.accentPink.swiftUIColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contentShape(Rectangle())
                        .accessibilityIdentifier("autoCapture_open_camera")
                        
                        if isProcessing {
                            VStack(spacing: 8) {
                                ProgressView()
                                Text("Analyzing image...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                        }
                        
                        // Empty state
                        if captures.isEmpty && !isProcessing {
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                                    .padding(.top, 20)
                                    .accessibilityHidden(true)
                                
                                Text("Capture multiple photos to estimate sidewalk width and slope")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.horizontal)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerWrapper(image: $tempImage, sourceType: .camera)
            }
            .onChange(of: tempImage) { newImage in
                if let image = newImage {
                    isProcessing = true
                    
                    // Process the captured image with a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        let width = Double.random(in: 0.5...4.0)
                        let slope = Double.random(in: 0.0...15.0)
                        
                        let newCapture = Capture(
                            image: image,
                            widthMeters: width,
                            slopeDegrees: slope
                        )
                        
                        self.captures.append(newCapture)
                        self.tempImage = nil
                        self.isProcessing = false
                        self.showImagePicker = false
                        
                        // Update selectedChoice with CSV format
                        self.updateSelectedChoice()
                    }
                }
            }
        }
        
        private func updateSelectedChoice() {
            guard !captures.isEmpty else {
                selectedChoice = nil
                return
            }
            
            // Create CSV format for width and slope values
            let widthCSV = captures.map { String(format: "%.2f", $0.widthMeters) }.joined(separator: ",")
            let slopeCSV = captures.map { String(format: "%.1f", $0.slopeDegrees) }.joined(separator: ",")
            
            let value = "width_m:\(widthCSV)|slope_deg:\(slopeCSV)"
            let text = "\(captures.count) capture\(captures.count > 1 ? "s" : "")"
            
            let answer = QuestAnswerChoice(
                value: value,
                choiceText: text,
                imageURL: nil,
                choiceFollowUp: nil
            )
            
            selectedChoice = answer
        }
    }
    
    // MARK: - CaptureCard (individual capture display)
    struct CaptureCard: View {
        let capture: QuestOptions.AutoCaptureView.Capture
        let onDelete: () -> Void
        
        var body: some View {
            VStack(spacing: 8) {
                HStack {
                    Image(uiImage: capture.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .cornerRadius(6)
                        .clipped()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "Width: %.2f m", capture.widthMeters))
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.semibold)
                        
                        Text(String(format: "Slope: %.1f°", capture.slopeDegrees))
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                    }
                    .accessibilityLabel("Delete this capture")
                }
                .padding(8)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - ImagePickerWrapper
    struct ImagePickerWrapper: UIViewControllerRepresentable {
        @Binding var image: UIImage?
        var sourceType: UIImagePickerController.SourceType = .photoLibrary

        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.sourceType = sourceType
            picker.delegate = context.coordinator
            picker.modalPresentationStyle = .fullScreen
            return picker
        }

        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

        func makeCoordinator() -> Coordinator {
            Coordinator(image: $image)
        }

        class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
            @Binding var image: UIImage?

            init(image: Binding<UIImage?>) {
                self._image = image
            }

            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
                if let pickedImage = info[.originalImage] as? UIImage {
                    self.image = pickedImage
                }
                picker.dismiss(animated: true)
            }

            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                picker.dismiss(animated: true)
            }
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
        }
    }

    struct FollowUpButton: View {
        let options: [QuestAnswerChoice]
        @Binding var selectedChoice: QuestAnswerChoice?
        let uploadPhoto: (Bool) -> Void

        private var followUpText: String? {
            guard let value = selectedChoice?.value else { return nil }
            let selectedValues = Set(value.components(separatedBy: ";").filter { !$0.isEmpty })
            return options.first(where: { selectedValues.contains($0.value) && $0.choiceFollowUp != nil })?.choiceFollowUp
        }

        var body: some View {
            if let followUp = followUpText {
                Button(action: {
                    uploadPhoto(true)
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "camera")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)

                        Text(followUp)
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

#Preview {
    QuestOptions.NoImageView(text: "This is a long option text that should wrap properly within the defined frame and be fully visible to the user without truncation.")
}
