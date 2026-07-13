//
//  CreateNoteView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 11/02/25.
//

import SwiftUI
import CoreLocation

struct CreateNoteView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var coordinates: CLLocationCoordinate2D
    @State private var noteText = ""
    @Binding var showNotesBox: Bool
    var prefillDraft: NoteDraft? = nil

    @State private var capturedImages: [UIImage] = []
    @State private var pickedImage: UIImage?
    @State private var isCameraPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L10n.Localizable.composeANote)
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

            ZStack(alignment: .topLeading) {
                TextEditor(text: $noteText)
                    .padding(2)
                    .background(Asset.Colors.f5F5F5LightGrayBackground.swiftUIColor)
                    .cornerRadius(8)
                    .padding()

                if noteText.isEmpty {
                    Text(L10n.Localizable.composeMessage)
                        .foregroundColor(Asset.Colors._83879BTextFiledTitle.swiftUIColor)
                        .padding()
                        .padding(.top, 10)
                        .padding(.leading, 5)
                }
            }

            photosSection

            HStack {
                Spacer()
                Button(action: {
                    submitNote()
                }) {
                    Text("Submit")
                        .font(FontFamily.Lato.bold.swiftUIFont(size: 20))
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 156, height: 46)
                        .background(noteText != "" ? Asset.Colors.huskyPurple.swiftUIColor : Color.gray)
                        .cornerRadius(23)
                }
                .disabled(noteText == "")
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 10)
        .onAppear {
            if let draft = prefillDraft {
                noteText = draft.noteText
                capturedImages = draft.images
            }
        }
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

    /// Hands the note off to NotesSubmissionManager and closes the sheet right away —
    /// the upload/submit runs in the background and reports back through
    /// MapViewPublisher, so the user isn't blocked waiting on it.
    func submitNote() {
        let draft = NoteDraft(
            id: prefillDraft?.id ?? UUID().uuidString,
            noteText: noteText,
            images: capturedImages,
            coordinates: coordinates
        )
        NotesSubmissionManager.submit(draft)
        showNotesBox = false
    }
}


#Preview {
    CreateNoteView(coordinates: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), showNotesBox: .constant(true))
}
