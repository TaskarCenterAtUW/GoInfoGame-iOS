//
//  ShortAnswersWithoutImage.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 31/07/24.
//

import SwiftUI
import PointNMapShared

struct QuestOptions: View {
    
    let quest: LongQuest
    
    var questOptions: [QuestAnswerChoice] {
        return quest.questAnswerChoices ?? []
    }
    
    @Binding var selectedChoice: QuestAnswerChoice?
    
    var questType: QuestType
    
    var uploadPhoto: (Bool) -> ()
    
    @AppStorage("lowBandwidthMode") private var lowBandwidthMode: Bool = false
    
    var body: some View {
        switch questType {
        case .exclusiveChoice:
            ExclusiveChoiceView(
                options: questOptions,
                selectedChoice: $selectedChoice,
                uploadPhoto: uploadPhoto
            )
        case .multipleChoice:
            MultipleChoiceView(
                options: questOptions,
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
            AutoCaptureView(tags: quest.questTags ?? [], selectedChoice: $selectedChoice)
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
        let tags: [String]
        @Binding var selectedChoice: QuestAnswerChoice?
        
        @State private var selectedClasses: [AccessibilityFeatureClass] = []
        @StateObject private var sharedAppData: SharedBaseData = SharedBaseData()
        @StateObject private var sharedAppContext: SharedBaseContext = SharedBaseContext()
        @StateObject private var segmentationPipeline: SegmentationARPipeline = SegmentationARPipeline()
        @StateObject private var sharedBaseSettings: SharedBaseSettings = SharedBaseSettings()
        let isEnhancedAnalysisEnabled = true
        @StateObject var segmentationAnnontationPipeline: SegmentationAnnotationPipeline = SegmentationAnnotationPipeline()
        @StateObject var attributeEstimationPipeline: AttributeEstimationPipeline = AttributeEstimationPipeline()
        @StateObject var manager: AnnotationImageManager = AnnotationImageManager()
//        class CurrentFeaturesViewModel: ObservableObject {
//            @Published var currentFeatures: [EditableAccessibilityFeature] = []
//        }
//        @StateObject private var currentFeaturesViewModel: CurrentFeaturesViewModel = CurrentFeaturesViewModel()
        
        // Data model for a single capture. Keys are OSM tags (e.g. "ext:autocapture-width").
        struct Capture: Identifiable {
            let id = UUID()
            let osmTags: [String: String]
        }

        // Reverse lookup: OSM tag key → human-readable display name, built from allCases.
        func osmTagDisplayNames(tags: [String]) -> [String: String] {
            var tagDisplayNames: [String: String] = [:]
            tags.forEach({ tag in
                    if let attribute = Self.accessibilityFeatureAttributeForOSMTag(tag: tag) {
                        tagDisplayNames[tag] = attribute.displayName
                    }
                })
            return tagDisplayNames
        }
        
        
        nonisolated private static func accessibilityFeatureAttributeForOSMTag(tag: String) -> AccessibilityFeatureAttribute? {
            switch tag {
            case "width": return .width
            case "incline": return .runningSlope
            case "ext:ac:cross-slope": return .crossSlope
            case "ext:ac:surface-integrity": return .surfaceIntegrity
            case "ext:ac:surface-disruption": return .surfaceDisruption
            case "ext:ac:height-from-ground": return .heightFromGround
            case "ext:ac:lidar-depth": return .lidarDepth
//            case "ext:ac:width-legacy": return .widthLegacy
//            case "ext:ac:running-slope-legacy": return .runningSlopeLegacy
//            case "ext:ac:cross-slope-legacy": return .crossSlopeLegacy
//            case "ext:ac:width-from-image": return .widthFromImage
//            case "ext:ac:running-slope-from-image": return .runningSlopeFromImage
//            case "ext:ac:cross-slope-from-image": return .crossSlopeFromImage
            default: return nil
            }
        }
            

        // Maps each AccessibilityFeatureAttribute to its OSM tag key.
//        nonisolated private static func osmTagKey(for attribute: AccessibilityFeatureAttribute) -> String? {
//            switch attribute {
//            case .width:                return "width" // For Sidewalk
//            case .runningSlope:         return "incline" // For Sidewalk
//            case .crossSlope:           return "ext:ac:crossing-slope" // For Sidewalk
//            case .surfaceIntegrity:     return "ext:autocapture-surface-integrity"
//            case .surfaceDisruption:    return "ext:autocapture-surface-disruption" // Got Long press feature
//            case .heightFromGround:     return "ext:autocapture-height-from-ground" // Got Long press feature
//            case .lidarDepth:           return "ext:autocapture-lidar-depth"
//            case .latitudeDelta:        return "ext:autocapture-latitude-delta"
//            case .longitudeDelta:       return "ext:autocapture-longitude-delta"
//            case .widthLegacy:          return "ext:autocapture-width-legacy"
//            case .runningSlopeLegacy:   return "ext:autocapture-running-slope-legacy"
//            case .crossSlopeLegacy:     return "ext:autocapture-cross-slope-legacy"
//            case .widthFromImage:       return "ext:autocapture-width-from-image"
//            case .runningSlopeFromImage: return "ext:autocapture-running-slope-from-image"
//            case .crossSlopeFromImage:  return "ext:autocapture-cross-slope-from-image"
//            default: return nil
//            }
//        }
        
        @State private var captures: [Capture] = []
        @State private var showImagePicker = false
        @State private var isProcessing = false
        @State private var lastSelectedChoiceValue: String = ""
        @State private var isProcessingError: Bool = false
        @State private var errorMessage: String = ""

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
                                        tagDisplayNames: osmTagDisplayNames(tags: tags ?? []),
                                        onDelete: {
                                            captures.removeAll { $0.id == capture.id }
                                            updateSelectedChoice()
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Only allow one capture at a time (temporary restriction)
                        if captures.isEmpty {
                            Button(action: {
                                showImagePicker = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                    Text("Open Camera")
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
                        }
                        
                        if isProcessing {
                            VStack(spacing: 8) {
                                ProgressView()
                                Text("Analyzing image may take few seconds...")
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
                                
                                Text("Capture a photo to estimate sidewalk width and slope")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.horizontal)
                            }
                        }
                        
                        if isProcessingError {
                            Text(errorMessage)
                                .foregroundColor(Color.red)
                                .padding(.horizontal, 20)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        isProcessingError = false
                                    }
                                }
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .onAppear {
                // Reconstruct captures from selectedChoice if the view was recreated during scroll
                if captures.isEmpty, let selected = selectedChoice, !selected.value.isEmpty {
                    if selected.value != lastSelectedChoiceValue {
                        let reconstructed = parseCaptures(from: selected.value)
                        if !reconstructed.isEmpty {
                            captures = reconstructed
                            lastSelectedChoiceValue = selected.value
                        }
                    }
                }
                configure()
            }
            .onChange(of: selectedChoice) { newChoice in
                // Monitor selectedChoice for external changes
                if let selected = newChoice, !selected.value.isEmpty, selected.value != lastSelectedChoiceValue {
                    if captures.isEmpty {
                        let reconstructed = parseCaptures(from: selected.value)
                        if !reconstructed.isEmpty {
                            captures = reconstructed
                            lastSelectedChoiceValue = selected.value
                        }
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ARCameraViewBase(selectedClasses: self.selectedClasses.sorted(), onCaptureComplete: onCaptureComplete)
                .environmentObject(self.sharedAppData)
                .environmentObject(self.sharedAppContext)
                .environmentObject(self.segmentationPipeline)
                .environmentObject(self.sharedBaseSettings)
            }
        }
        
        public func onCaptureComplete(captureData: CaptureData) {
            self.errorMessage = ""
            self.showImagePicker = false
            self.isProcessing = true

            // Snapshot all MainActor state before entering the background task.
            // Task.detached has no actor context, so @StateObject and other
            // @MainActor-isolated properties cannot be accessed inside it directly.
            let selectedClasses = self.selectedClasses
            let isEnhancedAnalysisEnabled = self.sharedBaseSettings.isEnhancedAnalysisEnabled
            let attributeEstimationPipeline = self.attributeEstimationPipeline
            let manager = self.manager
            let segmentationAnnontationPipeline = self.segmentationAnnontationPipeline
            let sharedAppData = self.sharedAppData

            Task.detached(priority: .userInitiated) {
                do {
                    var captureMeshData: (any CaptureMeshDataProtocol)? = nil
                    if isEnhancedAnalysisEnabled {
                        guard let captureMeshDataResults = captureData.meshData?.captureMeshDataResults else {
                            throw NSError(
                                domain: "CaptureMeshDataErrorDomain", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Mesh data is missing from capture data."]
                            )
                        }
                        captureMeshData = CaptureImageAndMeshData(
                            captureImageData: CaptureImageData(captureData.imageData),
                            captureMeshDataResults: captureMeshDataResults
                        )
                    }
                    try attributeEstimationPipeline.configure(
                        captureImageData: captureData.imageData,
                        captureMeshData: captureMeshData
                    )
                    try manager.configure(
                        selectedClasses: selectedClasses,
                        segmentationAnnotationPipeline: segmentationAnnontationPipeline,
                        captureImageData: captureData.imageData,
                        captureMeshData: captureMeshData,
                        isEnhancedAnalysisEnabled: isEnhancedAnalysisEnabled
                    )
                    let captureDataHistory = Array(await sharedAppData.captureDataQueue.snapshot())
                    manager.setupAlignedSegmentationLabelImages(captureDataHistory: captureDataHistory)

                    var newCaptures: [Capture] = []
                    for currentClass in selectedClasses {
                        let accessibilityFeatures = try manager.updateFeatureClass(accessibilityFeatureClass: currentClass)
                        for accessibilityFeature in accessibilityFeatures {
                            try attributeEstimationPipeline.setPrerequisites(accessibilityFeature: accessibilityFeature)
                            try attributeEstimationPipeline.processAttributeRequest(accessibilityFeature: accessibilityFeature)
                            attributeEstimationPipeline.clearPrerequisites()
                        }

                        var tags: [String: String] = [:]
                        for tag in self.tags {
                            if let accessAttribute = Self.accessibilityFeatureAttributeForOSMTag(tag: tag),
                               let aa = accessibilityFeatures.first?.attributeValues.first(where: { attribute in
                                   accessAttribute == attribute.key
                               }) {
                                   tags[tag] = aa.value?.toString() ?? "NA"
                            }
                        }
                        newCaptures.append(Capture(osmTags: tags))
                    }

                    let completedCaptures = newCaptures
                    await MainActor.run {
                        self.captures.append(contentsOf: completedCaptures)
                        self.isProcessing = false
                        self.updateSelectedChoice()
                    }
                } catch {
                    print("Error configuring attribute estimation pipeline: \(error)")
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                        self.isProcessingError = true
                        self.isProcessing = false
                    }
                }
            }
        }
        
        public func configure() {
            // For demonstration purposes, we select only sidewalk class by default
            guard let sidewalkClass = PointNMapConstants.SelectedAccessibilityFeatureConfig.classes.first(where: { $0.kind == .sidewalk }) else {
                return
            }
            self.sharedBaseSettings.isEnhancedAnalysisEnabled = self.isEnhancedAnalysisEnabled
            self.selectedClasses = [sidewalkClass]
            do {
                try self.sharedAppContext.configure()
                try segmentationPipeline.configure()
                try segmentationAnnontationPipeline.configure()
            } catch {
                print("Error during setup configuration: \(error)")
            }
        }
        
        private func updateSelectedChoice() {
            guard !captures.isEmpty else {
                selectedChoice = nil
                lastSelectedChoiceValue = ""
                return
            }

            // Serialize captures as capture blocks separated by "||".
            // Within each block, OSM tags are "key=value" pairs separated by "|".
            let value = captures.map { capture in
                capture.osmTags.sorted(by: { $0.key < $1.key })
                    .map { "\($0.key)=\($0.value)" }
                    .joined(separator: "|")
            }.joined(separator: "||")

            let text = "\(captures.count) capture\(captures.count > 1 ? "s" : "")"
            let answer = QuestAnswerChoice(value: value, choiceText: text, imageURL: nil, choiceFollowUp: nil)
            selectedChoice = answer
            lastSelectedChoiceValue = value
        }

        private func parseCaptures(from value: String) -> [Capture] {
            return value.components(separatedBy: "||").compactMap { block in
                let trimmed = block.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return nil }
                var tags: [String: String] = [:]
                for pair in trimmed.split(separator: "|") {
                    let kv = String(pair).split(separator: "=", maxSplits: 1)
                    if kv.count == 2 {
                        tags[String(kv[0])] = String(kv[1])
                    }
                }
                return tags.isEmpty ? nil : Capture(osmTags: tags)
            }
        }
    }
    
    // MARK: - CaptureCard (individual capture display)
    struct CaptureCard: View {
        let capture: QuestOptions.AutoCaptureView.Capture
        let tagDisplayNames: [String: String]
        let onDelete: () -> Void

        var body: some View {
            VStack(spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(capture.osmTags.sorted(by: { $0.key < $1.key }), id: \.key) { tag, value in
                            Text("\(tagDisplayNames[tag] ?? tag): \(value)")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.semibold)
                        }
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
        let jsonString = """
    {
                                      "quest_id": 101,
                                      "quest_title": "What is this sidewalk's surface type?",
                                      "quest_description": "Choose the primary surface material of the sidewalk.",
                                      "quest_type": "ExclusiveChoice",
                                      "quest_tag": "ext:surface",
    "quest_image_url": "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/main/images/kerb/lowered_landscape.png",
                  "quest_answer_choices": [
                    {
                      "value": "asphalt",
                      "choice_text": "Asphalt",
                      "image_url": "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/main/images/sidewalk/surface/asphalt_landscape.png"
                    }]
                    }
    """
        if let longQeust = try? JSONDecoder().decode(LongQuest.self, from: jsonString.data(using: .utf8)!) {
            QuestOptions(quest: longQeust,
                         selectedChoice: .constant(QuestAnswerChoice(value: "no", choiceText: "No, this roadway is too wide to cross safely.", imageURL: nil, choiceFollowUp: nil)),
                         questType: GoInfoGame.QuestType.exclusiveChoice) { s in
                
            }
        }
}

#Preview {
    QuestOptions.NoImageView(text: "This is a long option text that should wrap properly within the defined frame and be fully visible to the user without truncation.")
}
