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

/// LongForm's answer payload. Unlike every other quest form (which submits a bare
/// `[String:String]`), LongForm can also carry a captured-but-not-yet-uploaded
/// KartaView photo — the upload itself is deferred to `QuestSubmissionManager`'s
/// offline queue rather than attempted here, so Submit never has to wait on the
/// network (see QuestSubmissionManager.swift). This is LongForm's own `AnswerClass`;
/// no other quest form is affected by it.
struct LongFormAnswer {
    let tags: [String: String]
    let capturedImage: UIImage?
    let imageTagKey: String?
}

struct LongForm: View, QuestForm {

    // @StateObject (not @ObservedObject): LongForm is reconstructed as a fresh struct
    // value on every incidental parent re-render (e.g. QuestSheetView.init runs again
    // on each MapView.body re-evaluation while this sheet is open — including from
    // unrelated GPS/location updates during a photo capture+upload). @ObservedObject's
    // default-initializer expression re-runs on every such reconstruction, silently
    // replacing this view model — and with it, selectedChoices — while other @State
    // here (isLoading, uploadedPhotos, ...) survives because it's identity-keyed by
    // SwiftUI rather than owned by the struct. @StateObject ties the instance to the
    // view's identity instead, so it survives those re-inits.
    @StateObject private var viewModel = LongFormViewModel()

    var elementName: String?

    var questID: String?

    var query: String?

    var tags: [String: String]?

    /// When true, this form is answering a multi-select batch of elements at once
    /// (see `LongElementQuest.isMultiSelectMode`) — `tags` reflects only the first
    /// selected element's state, which can't represent the whole batch, so prefill
    /// is skipped and the form always starts blank.
    var isMultiSelectMode: Bool = false

    var action: ((LongFormAnswer) -> Void)?

    typealias AnswerClass = LongFormAnswer

    var coordinate: CLLocationCoordinate2D?

    @Environment(\.presentationMode) var presentationMode

    @State private var isCameraPresented = false
    @State private var capturedImage: UIImage?

    /// True once the user has dismissed the preview of a photo that was already
    /// synced on a previous visit (`tags?["ext:kartaview_url"]`) — hides that card and
    /// reveals the normal "take a photo" CTA again. Purely local UI state: nothing is
    /// changed server-side unless the user then captures and submits a new photo,
    /// which replaces the tag value the normal way.
    @State private var dismissedExistingPhoto = false

    /// Set in `.onAppear` when this element has a queued photo that has failed to
    /// upload 3+ times — drives `showPhotoRetryExhaustedAlert`. Checked only on
    /// reopen, not proactively, so it doesn't interrupt unrelated work.
    @State private var stuckPhotoChangeset: StoredChangesetSnapshot?
    @State private var showPhotoRetryExhaustedAlert = false

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
                        tagInfoRow(label: "ID", value: questID ?? "0")

                        tagInfoRow(label: "Intersection", value: tags?["ext:intersection_at"])

                        tagInfoRow(label: "Name", value: tags?["name"])

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
                                        }, hasPhotoAttached: hasPhotoAttached)
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

                        photoCard
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    Section {
                        submitButton
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .scrollContentBackground(.hidden)
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
                // Checked only here (on reopen), not proactively — a photo that's
                // still retrying quietly in the background shouldn't interrupt
                // whatever else the user is doing when the 3rd attempt happens.
                if let elementId = Int(questID ?? ""),
                   let stuck = DatabaseConnector.shared.stuckPhotoChangeset(elementId: elementId) {
                    stuckPhotoChangeset = stuck
                    showPhotoRetryExhaustedAlert = true
                }
            }
            .onChange(of: viewModel.selectedChoices) { _ in
                viewModel.clearAnswersForHiddenQuests()
            }
            .sheet(isPresented: $isCameraPresented) {
                CameraView(capturedImage: $capturedImage, isPresented: $isCameraPresented)
                    .applyPresentationSizingPage()
                   }
        }
        // Matches the background used everywhere else in the app (ManageQuestsView,
        // UserSettingsView, AccessibilityModeView, etc.) instead of the system's default
        // sheet background, so it looks consistent whether this sheet is a small preview
        // or expanded to full screen.
        .background(Color(red: 248 / 255, green: 248 / 255, blue: 248 / 255))
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
        .alert("Photo upload failed", isPresented: $showPhotoRetryExhaustedAlert, presenting: stuckPhotoChangeset) { changeset in
            Button("Retry") {
                QuestSubmissionManager.resumePendingUploads()
            }
            Button("Skip Photo & Submit", role: .destructive) {
                QuestSubmissionManager.skipPendingPhoto(changesetId: changeset.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: { changeset in
            Text("We couldn't upload the photo for \"\(elementName ?? "this element")\" after \(changeset.retryCount) attempts. You can try again, or submit the quest without the photo.")
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

    @ViewBuilder
    private func tagInfoRow(label: String, value: String?) -> some View {
        if let value {
            Text("\(label): \(value)")
                .font(.custom("Lato-Regular", size: 14, relativeTo: .headline))
                .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                .multilineTextAlignment(.leading)
                .accessibilityLabel("\(label): \(value)")
        }
    }

    /// True whenever `photoCard` below is showing something — captured this session,
    /// or already synced from a previous visit and not dismissed. Only one photo is
    /// kept per quest answer at a time, so the "take a photo" follow-up CTA
    /// (`FollowUpButton`, threaded down through `LongQuestView`/`QuestOptions`) hides
    /// itself whenever this is true; retaking still works via the camera icon on the
    /// card itself, which triggers the same `isCameraPresented` sheet.
    private var hasPhotoAttached: Bool {
        if capturedImage != nil { return true }
        if !dismissedExistingPhoto, let existing = tags?["ext:kartaview_url"], !existing.isEmpty { return true }
        return false
    }

    /// Local always wins over remote: a fresh capture this session supersedes
    /// whatever photo (if any) was already synced on a previous visit.
    @ViewBuilder
    private var photoCard: some View {
        if let capturedImage {
            photoCardRow(
                caption: "Photo attached",
                subcaption: "Uploads when you submit",
                onDelete: { self.capturedImage = nil }
            ) {
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .clipped()
            }
        } else if !dismissedExistingPhoto, let existingPhotoURL = tags?["ext:kartaview_url"], !existingPhotoURL.isEmpty {
            // LongFormImageView shows its own spinner while the remote thumbnail
            // loads, so there's no separate "loading" caption to swap out here.
            photoCardRow(
                caption: "Photo from last visit",
                subcaption: nil,
                onDelete: { dismissedExistingPhoto = true }
            ) {
                LongFormImageView(urlString: existingPhotoURL, width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    /// Framed thumbnail + circular delete badge, mirroring the photo-attach pattern
    /// already used in CreateNoteView/AddFeatureView — plus a retake button, which
    /// reuses the same camera sheet the "Other" follow-up choice opens.
    @ViewBuilder
    private func photoCardRow<Thumbnail: View>(
        caption: String,
        subcaption: String?,
        onDelete: @escaping () -> Void,
        @ViewBuilder thumbnail: () -> Thumbnail
    ) -> some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                thumbnail()

                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white, .black.opacity(0.6))
                }
                // Without this, List rows swallow this button's taps (same gotcha
                // documented on composeNoteButton/ignoreQuestButton below).
                .buttonStyle(.plain)
                .offset(x: -6, y: -6)
                .accessibilityLabel("Remove photo")
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(caption)
                    .font(.custom("Lato-Bold", size: 14, relativeTo: .headline))
                    .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                if let subcaption {
                    Text(subcaption)
                        .font(.custom("Lato-Regular", size: 12, relativeTo: .footnote))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: { isCameraPresented = true }) {
                Image(systemName: "camera.fill")
                    .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                    .frame(width: 32, height: 32)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Retake photo")
        }
        .padding(10)
        // Card treatment from the reference mockup: a bordered container around the
        // whole row, distinct from the plain list rows around it. Reuses the same
        // gray-stroke/corner-radius convention already used for option thumbnails
        // elsewhere in this quest UI (see QuestOptions.NoImageView) rather than
        // introducing a new color or radius.
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(10)
        .accessibilityElement(children: .combine)
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
                    // The user removed the previously-synced photo (dismissedExistingPhoto)
                    // and didn't capture a replacement — signal deletion the same way any
                    // other cleared answer does: an empty value drops the tag on sync
                    // (see OSMNode/OSMWay.toPayload's empty-value skip). Without this,
                    // dismissing the preview only hid it locally; the stale tag would
                    // still be there after Submit.
                    if capturedImage == nil, dismissedExistingPhoto, let existing = tags?["ext:kartaview_url"], !existing.isEmpty {
                        answersToSubmit["ext:kartaview_url"] = ""
                    }
                    // The photo (if any) is handed off unuploaded — QuestSubmissionManager's
                    // offline queue uploads it and merges the URL into the tags in the
                    // background, so Submit never waits on the network here.
                    action(LongFormAnswer(
                        tags: answersToSubmit,
                        capturedImage: capturedImage,
                        imageTagKey: capturedImage != nil ? "ext:kartaview_url" : nil
                    ))
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
