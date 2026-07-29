//
//  AddFeatureView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 06/02/25.
//

import SwiftUI
import CoreLocation
import osmapi

struct AddFeatureView: View {
    @Environment(\.presentationMode) var presentationMode
    /// A binding (not a one-time value) so it keeps reflecting the pin's position as
    /// the user drags the map underneath it while this sheet stays open.
    @Binding var tappedCoordinate: CLLocationCoordinate2D
    @Binding var isPresented: Bool
    @ObservedObject private var questsRepository = QuestsRepository.shared
    /// A binding (not local @State) so MapView can swap the on-screen pin's icon to
    /// match as soon as a preset is picked.
    @Binding var selectedPreset: FeaturePreset?

    /// Called once the submission sheet finishes — the message for the result alert,
    /// plus (if the newly created element satisfies a LongForm `quest_query`) the pin
    /// to add to the map and immediately open the quest flow for.
    @State var dismissSheet: (String, DisplayUnitWithCoordinate?) -> ()

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Select a feature to add")
                    .font(FontFamily.Lato.bold.swiftUIFont(fixedSize: 18))
                    .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                    .padding()

                Spacer()

                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(FontFamily.Lato.bold.swiftUIFont(size: 24))
                        .foregroundStyle(Asset.Colors._83879BTextFiledTitle.swiftUIColor)
                        .padding()
                }
            }

            if questsRepository.featurePresets.isEmpty {
                Spacer()
                Text("No feature presets are configured for this workspace.")
                    .font(FontFamily.Lato.regular.swiftUIFont(size: 14))
                    .foregroundColor(Asset.Colors._83879BTextFiledTitle.swiftUIColor)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
                        ForEach(questsRepository.featurePresets) { preset in
                            Button(action: { selectedPreset = preset }) {
                                VStack(spacing: 8) {
                                    PresetIconView(iconName: preset.icon, size: 36)
                                    Text(preset.name)
                                        .font(FontFamily.Lato.bold.swiftUIFont(size: 13))
                                        .foregroundColor(Asset.Colors._42526ETextFieldText.swiftUIColor)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 6)
                                .border(Asset.Colors.ddddddLine.swiftUIColor, width: 1)
                                .cornerRadius(5)
                            }
                            .accessibilityLabel(preset.name)
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $selectedPreset) { preset in
            FeatureSubmissionView(
                preset: preset,
                coordinate: $tappedCoordinate,
                onSubmit: { message, matchedQuestUnit in
                    // Dismiss the (inner) submission sheet first, then the (outer) picker
                    // sheet once its close animation clears — mirrors the same
                    // sequenced-sheet-transition pattern MapView uses elsewhere.
                    selectedPreset = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isPresented = false
                        dismissSheet(message, matchedQuestUnit)
                    }
                }
            )
            .presentationDetents([.fraction(0.6)])
            .presentationDragIndicator(.visible)
            .applyPresentationSizingPage()
        }
    }
}

/// Icon for a feature preset — tries the asset catalog first (e.g. the OSM/iD preset
/// icon set under `AddFeatureIcons`), and falls back to downloading whichever
/// `CustomIcon` in `QuestsRepository.shared.customIcons` matches by name, caching the
/// result the same way `LongFormImageView` does for in-quest illustration images.
struct PresetIconView: View {
    let iconName: String
    var size: CGFloat = 28

    @State private var remoteImage: UIImage?

    var body: some View {
        Group {
            if let localImage = UIImage(named: iconName) {
                Image(uiImage: localImage)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
            } else if let remoteImage {
                Image(uiImage: remoteImage)
                    .resizable()
            } else {
                Image(systemName: "mappin.circle")
                    .resizable()
                    .foregroundStyle(Asset.Colors._83879BTextFiledTitle.swiftUIColor)
                    .onAppear(perform: loadRemoteIconIfNeeded)
            }
        }
        .scaledToFit()
        .frame(width: size, height: size)
    }

    private func loadRemoteIconIfNeeded() {
        guard remoteImage == nil,
              let urlString = QuestsRepository.shared.customIcons.first(where: { $0.name == iconName })?.url,
              let url = URL(string: urlString) else { return }

        if let cached = ImageCache.shared.image(forKey: urlString) {
            remoteImage = cached
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            ImageCache.shared.set(image: image, forKey: urlString)
            DispatchQueue.main.async { remoteImage = image }
        }.resume()
    }
}

/// Shown after picking a preset from `AddFeatureView`'s grid — mirrors
/// `CreateNoteView`'s shape (notes text + photo capture) but submits an OSM node
/// tagged with the preset's `tags` instead of an OSM note.
struct FeatureSubmissionView: View {
    @Environment(\.presentationMode) var presentationMode
    let preset: FeaturePreset
    /// Live — reflects wherever the pin currently sits if the user drags the map
    /// underneath it (see `MapView.pinEditAnchor`/`editedCoordinate`) while this stays open.
    @Binding var coordinate: CLLocationCoordinate2D
    var onSubmit: (String, DisplayUnitWithCoordinate?) -> Void

    @State private var noteText = ""
    @State private var capturedImages: [UIImage] = []
    @State private var pickedImage: UIImage?
    @State private var isCameraPresented = false
    @State private var isSubmitting = false

    /// `ext:notes` is capped at this length server-side.
    private static let maxNoteLength = 255

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                PresetIconView(iconName: preset.icon, size: 28)
                Text(preset.name)
                    .font(FontFamily.Lato.bold.swiftUIFont(fixedSize: 18))
                    .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)

                Spacer()

                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(FontFamily.Lato.bold.swiftUIFont(size: 24))
                        .foregroundStyle(Asset.Colors._83879BTextFiledTitle.swiftUIColor)
                }
            }
            .padding()

            ZStack(alignment: .topLeading) {
                TextEditor(text: $noteText)
                    .padding(2)
                    .background(Asset.Colors.f5F5F5LightGrayBackground.swiftUIColor)
                    .cornerRadius(8)
                    .padding()

                if noteText.isEmpty {
                    Text("Add any notes about this feature (optional)")
                        .foregroundColor(Asset.Colors._83879BTextFiledTitle.swiftUIColor)
                        .padding()
                        .padding(.top, 10)
                        .padding(.leading, 5)
                }
            }
            .onChange(of: noteText) { newValue in
                if newValue.count > Self.maxNoteLength {
                    noteText = String(newValue.prefix(Self.maxNoteLength))
                }
            }

            Text("\(noteText.count)/\(Self.maxNoteLength)")
                .font(FontFamily.Lato.regular.swiftUIFont(size: 12))
                .foregroundColor(Asset.Colors._83879BTextFiledTitle.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal)

            photosSection

            HStack {
                Spacer()
                Button(action: { Task { await submit() } }) {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 156, height: 46)
                            .background(Asset.Colors.huskyPurple.swiftUIColor)
                            .cornerRadius(23)
                    } else {
                        Text("Submit")
                            .font(FontFamily.Lato.bold.swiftUIFont(size: 20))
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 156, height: 46)
                            .background(Asset.Colors.huskyPurple.swiftUIColor)
                            .cornerRadius(23)
                    }
                }
                .disabled(isSubmitting)
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 10)
        .sheet(isPresented: $isCameraPresented) {
            CameraView(capturedImage: $pickedImage, isPresented: $isCameraPresented)
        }
        .onChange(of: pickedImage) { newValue in
            if let image = newValue {
                capturedImages.append(image)
                pickedImage = nil
            }
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                isCameraPresented = true
            } label: {
                HStack {
                    Image(systemName: "camera")
                    Text(capturedImages.isEmpty ? "Add Photo" : "Add Another Photo")
                }
                .font(FontFamily.Lato.bold.swiftUIFont(size: 16))
                .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
            }
            .padding(.horizontal)

            if !capturedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(capturedImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .clipped()

                                Button {
                                    capturedImages.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white, .black.opacity(0.6))
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    /// Builds the node from the preset's tags — plus the note as `ext:notes` (capped at
    /// `maxNoteLength`) and each uploaded photo as its own `ext:image_N` tag — then
    /// creates it at the current coordinate.
    ///
    /// If creation succeeds, the node is also persisted locally under the server's real
    /// id/version (never returned any other way — see `DatasyncManager.uploadNode`) and
    /// checked against the LongForm `quest_query` filters: if it satisfies one, the
    /// caller gets back a ready-to-show quest pin so it can drop straight into that
    /// quest's flow instead of just sitting there unanswered.
    private func submit() async {
        isSubmitting = true

        var tags = preset.tags
        let trimmedNote = String(noteText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.maxNoteLength))
        if !trimmedNote.isEmpty {
            tags["ext:notes"] = trimmedNote
        }
        let photoURLs = await uploadPhotos()
        for (index, url) in photoURLs.enumerated() {
            tags["ext:image_\(index + 1)"] = url
        }

        let node = UserNodesHelper.getPowerPole(
            lat: coordinate.latitude,
            lon: coordinate.longitude,
            changeset: 1,
            tags: tags
        )

        var resultMessage = "\(preset.name) added successfully"
        var matchedQuestUnit: DisplayUnitWithCoordinate?
        do {
            let created = try await DatasyncManager.shared.createNode(node: node)

            let persistedNode = OSMNode(
                type: "node", id: created.id, lat: coordinate.latitude, lon: coordinate.longitude,
                timestamp: Date(), version: created.version, changeset: 0, user: "", uid: 0, tags: tags
            )
            DatabaseConnector.shared.saveOSMElements([persistedNode])
            matchedQuestUnit = AppQuestManager.shared.getUpdatedQuest(elementId: "\(created.id)")

            // Makes this creation undoable — shows up in the Undo sidebar right away,
            // and deletes the node (rather than reverting tags) if the user undoes it.
            _ = DatabaseConnector.shared.createChangesetForNewElement(
                id: created.id,
                questType: preset.name,
                tags: tags,
                version: created.version,
                iconName: preset.icon,
                point: coordinate
            )
        } catch {
            print("ERROR IN CREATING FEATURE ---->>> \(error)")
            resultMessage = "Something went wrong. Try again"
        }

        await MainActor.run {
            isSubmitting = false
            onSubmit(resultMessage, matchedQuestUnit)
        }
    }

    private func uploadPhotos() async -> [String] {
        guard !capturedImages.isEmpty else { return [] }
        var urls: [String] = []
        for image in capturedImages {
            let kartaviewViewModel = KartaviewViewModel(capturedImage: image)
            let (path, success) = await withCheckedContinuation { continuation in
                kartaviewViewModel.createSequence { path, success in
                    continuation.resume(returning: (path, success))
                }
            }
            if success {
                urls.append(path)
            }
        }
        return urls
    }
}

#Preview {
    AddFeatureView(tappedCoordinate: .constant(CLLocationCoordinate2D(latitude: 0, longitude: 0)), isPresented: .constant(true), selectedPreset: .constant(nil), dismissSheet: {_,_  in })
}
