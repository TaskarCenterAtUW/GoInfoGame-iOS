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
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(elementName ?? "")
                            .font(.custom("Lato-Bold", size: 16, relativeTo: .headline))
                            .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .accessibilityLabel(elementName ?? "")
                        Spacer()
                        LongFormDismissButtonView {
                            withAnimation {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }.padding(EdgeInsets(top: 20, leading: 20, bottom: 10, trailing: 20))
                    .layoutPriority(1)
                
                Text("ID: \(questID ?? "0")")
                    .font(.custom("Lato-Regular", size: 14, relativeTo: .headline))
                    .padding([.leading], 20)
                    .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .layoutPriority(1)
                    .accessibilityLabel("ID: \(questID ?? "0")")
                HStack {
                    Button {
                        showNotesBox = true
                    } label: {
                        Text(" Compose Note")
                            .font(.custom("Lato-Bold", size: 14, relativeTo: .headline))
                            .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 10)
                            .accessibilityLabel("Compose Note")
                    }
                    .padding(EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 20))
                    Spacer()
                    Button {
                        activeAlert = .hideQuestConfirmation
                    } label: {
                        Text("Ignore this quest")
                            .font(.custom("Lato-Bold", size: 14, relativeTo: .headline))
                            .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 10)
                            .accessibilityLabel("Ignore this quest")
                    }
                    .padding(.trailing, 20)
                }
                .layoutPriority(1)
                
                if showCreateNoteMessage {
                    Text(alertMessage)
                        .foregroundColor(alertMessage == "Note submitted successfully" ? Color.green : Color.red)
                        .padding(.horizontal, 20)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                showCreateNoteMessage = false
                            }
                        }
                }
        
                if showNotesBox {
                    VStack(alignment: .leading, spacing: 10) {
                        TextEditor(text: $noteText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal, 20)
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
                                        .font(.custom("Lato-Bold", size: 16))
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(noteText != "" ? Asset.Colors.huskyPurple.swiftUIColor : Color.gray)
                                        .cornerRadius(9)
                                        .accessibilityLabel("Submit this note")
                                }
                            }
                            .disabled(noteText == "")
                
                            Button (action: {
                                showNotesBox = false
                            }) {
                                Text("Cancel")
                                    .font(.custom("Lato-Bold", size: 16))
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Asset.Colors.accentPink.swiftUIColor)
                                    .cornerRadius(9)
                                    .accessibilityLabel("Cancel note composition")
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 10)
                }
                
                VStack {
                    List {
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
                            VStack {
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
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Text("No Quests available")
                        }
                    }
                    .padding(.bottom, keyboardHeight)
                    .onReceive(Publishers.keyboardHeight) { height in
                        let safeAreaBottom = UIApplication.shared.safeAreaBottomInset
                        withAnimation {
                            keyboardHeight = max(0, height - safeAreaBottom)
                        }
                    }
                }
                .hideKeyboardOnTap()
                
                Button(action: {
                    var answersToSubmit = viewModel.getAnswersForSubmission()
                    if !answersToSubmit.isEmpty {
                        if let action = action {
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
                        .background(Asset.Colors.huskyPurple.swiftUIColor)
                        .multilineTextAlignment(.center)
                        .cornerRadius(20)
                        .accessibilityLabel("Submit Answers")
                }
                .frame(maxWidth: .infinity)

            }
            .padding(.top, 30)
            .onAppear {
                deviceSupportsLiDAR = LiDARDetection.shared.isLiDARSupported()
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
                viewModel.selectedChoices[quest.questID] = $0
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
