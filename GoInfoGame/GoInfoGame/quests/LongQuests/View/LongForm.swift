//
//  SidewalkLongForm.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 22/07/24.
//

import SwiftUI
import CoreLocation
import Combine

enum LongFormActiveAlert: Identifiable {
    case hideQuestConfirmation
    case submissionError(message: String)

    var id: String {
        // Using a simple string representation for the ID ensures each case is unique.
        String(describing: self)
    }
}

struct LongForm: View, QuestForm {

    @ObservedObject private var viewModel = LongFormViewModel()

    var elementName: String?

    var questID: String?

    var query: String?

    var tags: [String: String]?

    /// When true, this form is answering a multi-select batch of elements at once
    /// (see `LongElementQuest.isMultiSelectMode`) — `tags` reflects only the first
    /// selected element's state, which can't represent the whole batch, so prefill
    /// is skipped and the form always starts blank.
    var isMultiSelectMode: Bool = false

    var action: (([String:String]) -> Void)?

    typealias AnswerClass = [String:String]

    var coordinate: CLLocationCoordinate2D?

    @Environment(\.presentationMode) var presentationMode

    @State private var showKartaviewAlert = false

    @State private var kartaViewAlert = ""

    @State private var isCameraPresented = false
    @State private var capturedImage: UIImage?

    @State private var isLoading = false

    @State private var showImagePath = false

    @State private var imagePath = ""

    @State private var uploadedPhotos: [String] = []

    @State private var showNotesBox = false

    @State private var noteText = ""

    @State private var alertMessage = ""

    @State private var showCreateNoteMessage = false

    @StateObject private var noteViewModel = NotesViewModel()

    @State private var keyboardHeight: CGFloat = 0

    @State private var activeAlert: LongFormActiveAlert?

    @State private var submitStatusMessage: String?

    @State private var deviceSupportsLiDAR: Bool = false

    @State private var hasPrefilled = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ZStack {
            // Title/dismiss stay pinned outside the List so dismiss is always reachable
            // without scrolling. Everything else — ID, intersection, note composition,
            // the quest list, and Submit — lives inside one continuous List (as sections),
            // so it all shares space and scrolls together, instead of the previous design
            // where those fixed elements sat outside the list and could squeeze its
            // available height down to almost nothing at large accessibility text sizes
            // (this sheet has a fixed maximum height with no way to grow further).
            VStack(spacing: 0) {
                header

                List {
                    Section {
                        Text("ID: \(questID ?? "0")")
                            .font(.custom("Lato-Regular", size: 14, relativeTo: .headline))
                            .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                            .multilineTextAlignment(.leading)
                            .accessibilityLabel("ID: \(questID ?? "0")")

                        if let intersectionAt = tags?["ext:intersection_at"] {
                            Text("Intersection: \(intersectionAt)")
                                .font(.custom("Lato-Regular", size: 14, relativeTo: .headline))
                                .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                                .multilineTextAlignment(.leading)
                                .accessibilityLabel("Intersection: \(intersectionAt)")
                        }

                        // Side by side, neither button has enough width at large
                        // accessibility text sizes to fit its label as a whole word, so
                        // both wrap mid-word. Stacking them instead gives each the full
                        // row width.
                        Group {
                            if dynamicTypeSize.isAccessibilitySize {
                                VStack(alignment: .leading, spacing: 8) {
                                    composeNoteButton
                                    ignoreQuestButton
                                }
                            } else {
                                HStack {
                                    composeNoteButton
                                    Spacer()
                                    ignoreQuestButton
                                }
                            }
                        }

                        if showCreateNoteMessage {
                            Text(alertMessage)
                                .foregroundColor(alertMessage == "Note submitted successfully" ? Color.green : Color.red)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        showCreateNoteMessage = false
                                    }
                                }
                        }

                        if showNotesBox {
                            notesBoxContent
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    Section {
                        if let quests = questsForLongForm()?.quests {
                            ForEach(quests, id: \.questID) { quest in
                                if viewModel.shouldShowQuest(quest) {
                                    if canShowQuest(quest) {
                                        LongQuestView(quest: quest, selectedChoice: binding(for: quest), uploadPhoto:  { result in
                                            if result { isCameraPresented = true }
                                        })
                                    }
                                }
                            }
                            if let statusMessage = submitStatusMessage {
                                Text(statusMessage)
                                    .font(.custom("Lato-Bold", size: 16, relativeTo: .headline))
                                    .foregroundColor(.red)
                                    .background(Color.white)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            submitStatusMessage = nil
                                        }
                                    }
                                    .accessibilityHidden(true)
                            }
                        } else {
                            Text("No Quests available")
                        }
                    }

                    Section {
                        submitButton
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .padding(.bottom, keyboardHeight)
                .onReceive(Publishers.keyboardHeight) { height in
                    let safeAreaBottom = UIApplication.shared.safeAreaBottomInset
                    withAnimation {
                        keyboardHeight = max(0, height - safeAreaBottom)
                    }
                }
                .hideKeyboardOnTap()
            }
            .onAppear {
                deviceSupportsLiDAR = LiDARDetection.shared.isLiDARSupported()
                if !hasPrefilled {
                    hasPrefilled = true
                    if !isMultiSelectMode {
                        viewModel.prefillAnswers(tags: tags ?? [:])
                    }
                }
            }
            .onChange(of: viewModel.selectedChoices) { _ in
                viewModel.clearAnswersForHiddenQuests()
            }
            .onChange(of: capturedImage) { newValue in
                if newValue != nil {
                    uploadImageToKartaView()
                }
            }
            .sheet(isPresented: $isCameraPresented) {
                CameraView(capturedImage: $capturedImage, isPresented: $isCameraPresented)
                    .applyPresentationSizingPage()
                   }

        if showKartaviewAlert {
            VStack {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .foregroundColor(.green)
                    .padding(.bottom, 50)
                Text("Image uploaded to Kartaview")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(10)
            }
            .padding([.all], 50)
            .background(Color.white)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Image uploaded to Kartaview")
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    showKartaviewAlert = false // Dismiss notification box after 1 second
                }
            }
        }

        if isLoading {
            VStack {
                ProgressView("Uploading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }
        }
        .alert(item: $activeAlert) { alertType in
            switch alertType {
            case .hideQuestConfirmation:
                return Alert(
                    title: Text("Do you want to ignore this question?"),
                    primaryButton: .destructive(Text("Ignore and Hide")) {
                        withAnimation {
                            MapViewPublisher.shared.dismissSheet.send(.hideElement(questID ?? "0", elementName ?? ""))
                            presentationMode.wrappedValue.dismiss()
                        }
                    },
                    secondaryButton: .cancel()
                )
            case .submissionError(let message):
                return Alert(title: Text(message), dismissButton: .default(Text("OK")))
            }
        }
    }

    func submitNote() async throws {
        print("Note to be submitted: \(noteText.htmlEscape())")

        do {
            //gt lat long from coordinate
            let lat = coordinate?.latitude ?? 0.0
            let long = coordinate?.longitude ?? 0.0
            print("Latitude: \(lat), Longitude: \(long)")

            let noteToBeSubmitted = noteText.htmlEscape()

            let notesResult = try await noteViewModel.createNote(note: noteToBeSubmitted, lat: lat, long: long)

            if notesResult {
                print("Notes composed successfully")
                alertMessage = "Note submitted successfully"
                showCreateNoteMessage = true

            } else {
                alertMessage = "Error creating note"
                showCreateNoteMessage = true
            }
        } catch {
            alertMessage = "Error creating note: \(error.localizedDescription)"
            print("Error creating note: \(error.localizedDescription)")
            throw error
        }

        await MainActor.run {
            noteViewModel.isLoading = false
            showNotesBox = false
        }
    }

    func uploadImageToKartaView() {
        isLoading = true
        let kvViewModel = KartaviewViewModel(capturedImage: capturedImage!)
        kvViewModel.createSequence(completion: { (path,result) in
            isLoading = false
            kartaViewAlert = result ? "Upload Successful" : "Upload Failed"
            showKartaviewAlert = true
            showImagePath = true
            imagePath = path
            print("KARTAVIEW IMAGE PATH --->>>\(path)")
            uploadedPhotos.append(path)
            print(uploadedPhotos)
        })
    }

    func questsForLongForm() -> LongFormElement? {
        let element = QuestsRepository.shared.questElementForQuery(query ?? "")
        viewModel.longForm = element
        return element
    }

    private func binding(for quest: LongQuest) -> Binding<QuestAnswerChoice?> {
        return Binding(
            get: { viewModel.selectedChoices[quest.questID, default: nil] },
            set: {
                // `selectedChoices[quest.questID] = $0` would, when $0 is nil, remove
                // the key entirely (Swift's subscript-assign-nil-removes-key rule) —
                // indistinguishable from "never touched this session". updateValue
                // stores an explicit nil instead, so getAnswersForSubmission can tell
                // "deselected/cleared" (must remove the tag) apart from "untouched"
                // (leave the tag alone).
                viewModel.selectedChoices.updateValue($0, forKey: quest.questID)
            }
        )
    }

    private func canShowQuest(_ quest: LongQuest) -> Bool {
        guard let questType = quest.questType else {
            return false
        }
        if questType == .autoCapture {
            if deviceSupportsLiDAR {
                return true
            }
            return false
        }
        return true
    }

    private var header: some View {
        // Side by side, the title has to share its row with the close button; at large
        // accessibility text a single-word element name can need more width than that
        // leaves it, so it wraps mid-word. Stacking them instead gives the title the
        // full row width. `.fixedSize(vertical: true)` on the title forces it to always
        // render at its true (possibly multi-line) height rather than being squeezed
        // into its old single-line allocation, which caused the row below to overlap it.
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Spacer()
                        dismissButton
                    }
                    titleText
                }
            } else {
                HStack {
                    titleText
                    Spacer()
                    dismissButton
                }
            }
        }
        .padding(EdgeInsets(top: 20, leading: 20, bottom: 10, trailing: 20))
        .background(Color.white)
    }

    private var titleText: some View {
        Text(elementName ?? "")
            .font(.custom("Lato-Bold", size: 16, relativeTo: .headline))
            .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(elementName ?? "")
    }

    private var dismissButton: some View {
        LongFormDismissButtonView {
            withAnimation {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    private var composeNoteButton: some View {
        Button {
            showNotesBox = true
        } label: {
            Text(" Compose Note")
                .font(.custom("Lato-Bold", size: 14, relativeTo: .headline))
                .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                .multilineTextAlignment(.center)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityLabel("Compose Note")
        }
        // Without this, List rows apply their own default button/selection styling —
        // with two buttons sharing one row (this + ignoreQuestButton below) that made
        // taps land on the wrong button or not register at all.
        .buttonStyle(.plain)
    }

    private var ignoreQuestButton: some View {
        Button {
            activeAlert = .hideQuestConfirmation
        } label: {
            Text("Ignore this quest")
                .font(.custom("Lato-Bold", size: 14, relativeTo: .headline))
                .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                .multilineTextAlignment(.center)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityLabel("Ignore this quest")
        }
        .buttonStyle(.plain)
    }

    private var notesBoxContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextEditor(text: $noteText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                // TextEditor has no intrinsic size the way Text does — as a row inside a
                // List Section it was collapsing to near-zero height, making it invisible.
                .frame(minHeight: 100)
                .border(Asset.Colors.huskyPurple.swiftUIColor)
                .accessibilityLabel("Note text editor")

            HStack {
                Button(action: {
                    Task {
                        do {
                            try await submitNote()
                        } catch {
                           showCreateNoteMessage = true
                            showNotesBox = false

                        }
                    }
                }) {
                    if noteViewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Submit")
                            .font(.custom("Lato-Bold", size: 16, relativeTo: .headline))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(noteText != "" ? Asset.Colors.huskyPurple.swiftUIColor : Color.gray)
                            .cornerRadius(9)
                            .accessibilityLabel("Submit this note")
                    }
                }
                .buttonStyle(.plain)
                .disabled(noteText == "")

                Button (action: {
                    showNotesBox = false
                }) {
                    Text("Cancel")
                        .font(.custom("Lato-Bold", size: 16, relativeTo: .headline))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Asset.Colors.accentPink.swiftUIColor)
                        .cornerRadius(9)
                        .accessibilityLabel("Cancel note composition")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 10)
    }

    private var submitButton: some View {
        Button(action: {
            var answersToSubmit = viewModel.getAnswersForSubmission()
            if !answersToSubmit.isEmpty {
                if let validationError = viewModel.validationErrorMessage() {
                    self.submitStatusMessage = validationError
                    self.activeAlert = .submissionError(message: validationError)
                } else if let action = action {
                    if !uploadedPhotos.isEmpty {
                        answersToSubmit["ext:kartaview_url"] = uploadedPhotos.joined(separator: ", ")
                    }
                      action(answersToSubmit)
                }
            } else {
                self.submitStatusMessage = "Please answer atleast one quest to submit"
                self.activeAlert = .submissionError(message: "Please answer atleast one quest to submit")
            }

        }) {
            Text("Submit")
                .font(.custom("Lato-Bold", size: 16, relativeTo: .title))
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 40)
                .background(viewModel.validationErrorMessage() != nil ? Color.gray : Asset.Colors.huskyPurple.swiftUIColor)
                .multilineTextAlignment(.center)
                .cornerRadius(20)
                .accessibilityLabel("Submit Answers")
        }
        .buttonStyle(.plain)
        .disabled(viewModel.validationErrorMessage() != nil)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let jsonString = """
        {
              "element_type": "Crossings",
              "element_type_icon": "pedestrian_crossing",
              "quest_query": "ways with (highway=footway and footway=crossing)",
              "quests": [
                {
                  "quest_id": 201,
                  "quest_title": "Does this crossing have markings on the roadway?",
                  "quest_description": "Check if there are roadway markings present at this crossing.",
                  "quest_type": "ExclusiveChoice",
                  "quest_tag": "crossing:markings",
                  "quest_answer_choices": [
                    {
                      "value": "no",
                      "choice_text": "No",
                      "image_url": "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/main/images/crossing/markings/no_square.png"
                    },
                    {
                      "value": "yes",
                      "choice_text": "Yes",
                      "image_url": "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/main/images/crossing/markings/zebra_square.png"
                    }
                  ]
                }
              ]
            }
        """

    guard let quest = try? JSONDecoder().decode(LongFormElement.self, from: jsonString.data(using: .utf8)!) else {
        return Text("Error parsing JSON")
    }
    QuestsRepository.shared.longQuestModels.append(quest)
    return LongForm(elementName: quest.elementType, questID: "questId",query: quest.questQuery, action: nil)
}
