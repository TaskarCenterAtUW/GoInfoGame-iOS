//
//  SidewalkLongForm.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 22/07/24.
//

import SwiftUI
import CoreLocation
import Combine

struct LongForm: View, QuestForm {
    
    @ObservedObject private var viewModel = LongFormViewModel()
        
    var elementName: String?
    
    var questID: String?
    
    var query: String?
    
    var action: (([String:String]) -> Void)?
    
    typealias AnswerClass = [String:String]
    
    var coordinate: CLLocationCoordinate2D?
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showSubmitAlert = false
    
    @State private var showKartaviewAlert = false
    
    @State private var submitAlert = ""
    
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
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                    HStack {
                        Text(elementName ?? "")
                            .font(.custom("Lato-Bold", size: 16))
                            .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                        Spacer()
                        LongFormDismissButtonView {
                            withAnimation {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }.padding(EdgeInsets(top: 20, leading: 20, bottom: 10, trailing: 20))
                
                Text("ID: \(questID ?? "0")")
                    .font(.custom("Lato-Regular", size: 13))
                    .padding([.leading], 20)
                    .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                
                HStack {
                    Button {
                        showNotesBox = true
                    } label: {
                        Text(" Compose Note")
                            .font(.custom("Lato-Bold", size: 15))
                            .foregroundStyle(Asset.Colors.accentPink.swiftUIColor)
                    }
                    .padding(EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 20))
                    Spacer()
                    Button("Hide this") {
                        withAnimation {
                            MapViewPublisher.shared.dismissSheet.send(.hideElement(questID ?? "0", elementName ?? ""))
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .padding(.trailing, 20)
                    .foregroundStyle(Asset.Colors.accentPink.swiftUIColor)
                }
                
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
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 10)
                }
                
                VStack {
                    List {
                        if let quests = questsForLongForm() {
                            ForEach(quests, id: \.questID) { quest in
                                if viewModel.shouldShowQuest(quest) {
                                    LongQuestView(quest: quest, selectedChoice: binding(for: quest), uploadPhoto:  { result in
                                        if result { isCameraPresented = true }
                                    })
                                }
                            }
                            VStack {
                                if showSubmitAlert {
                                    Text(submitAlert)
                                        .font(.custom("Lato-Bold", size: 16))
                                        .foregroundColor(.red)
                                        .background(Color.white)
                                        .onAppear {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                showSubmitAlert = false
                                            }
                                        }
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
                        self.showSubmitAlert = true
                        self.submitAlert = "Please answer atleast one quest to submit"
                    }

                }) {
                    Text("Submit")
                        .font(.custom("Lato-Bold", size: 16))
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 200, height: 40)
                        .background(Asset.Colors.huskyPurple.swiftUIColor)
                        .cornerRadius(20)
                }
                .frame(maxWidth: .infinity)

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
                   }
        }
        .alert(self.submitAlert, isPresented: $showSubmitAlert) {
            Button("OK", role: .cancel) { }
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
    
    func questsForLongForm() -> [LongQuest]? {
        return QuestsRepository.shared.questsForQuery(query ?? "")       
    }
    
    private func binding(for quest: LongQuest) -> Binding<QuestAnswerChoice?> {
        return Binding(
            get: { viewModel.selectedChoices[quest.questID, default: nil] },
            set: {
                viewModel.selectedChoices[quest.questID] = $0
            }
        )
    }
}

#Preview {
    let jsonString = """
        {
              "element_type": "Sidewalks",
              "element_type_icon": "sidewalk",
              "quest_query": "ways with (highway=footway and footway=sidewalk)",
              "quests": [
                {
                  "quest_id": 101,
                  "quest_title": "What is this sidewalk's surface type?",
                  "quest_description": "Choose the primary surface material of the sidewalk.",
                  "quest_type": "ExclusiveChoice",
                  "quest_tag": "ext:surface",
                  "quest_answer_choices": [
                    {
                      "value": "asphalt",
                      "choice_text": "Asphalt",
                      "image_url": "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/main/images/sidewalk/surface/asphalt_landscape.png"
                    },
                    {
                      "value": "concrete",
                      "choice_text": "Concrete",
                      "image_url": "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/main/images/sidewalk/surface/concrete_landscape.png"
                    },
                    {
                      "value": "paving_stones",
                      "choice_text": "Brick",
                      "image_url": "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/main/images/sidewalk/surface/brick_landscape.png"
                    },
                    {
                      "value": "gravel",
                      "choice_text": "Gravel",
                      "image_url": "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/main/images/sidewalk/surface/compacted_gravel_landscape.png"
                    },
                    {
                      "value": "other",
                      "choice_text": "Other"
                    }
                  ]
                },
                {
                  "quest_id": 103,
                  "quest_title": "How wide is this sidewalk, in inches?",
                  "quest_description": "Specify the width of this sidewalk, in inches.",
                  "quest_image_url": "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/main/images/sidewalk/dimension/width_square.png",
                  "quest_type": "Numeric",
                  "quest_tag": "width",
                  "quest_answer_validation": {
                    "min": 12,
                    "max": 240
                  }
                },
                {
                  "quest_id": 104,
                  "quest_title": "Are there any obstructions along this sidewalk?",
                  "quest_description": "Check if there are any obstructions blocking this sidewalk.",
                  "quest_image_url": "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/main/images/sidewalk/obstruction/street_furniture_square.png",
                  "quest_type": "ExclusiveChoice",
                  "quest_tag": "ext:obstruction",
                  "quest_answer_choices": [
                    {
                      "value": "yes",
                      "choice_text": "Yes"
                    },
                    {
                      "value": "no",
                      "choice_text": "No"
                    }
                  ]
                },
                {
                  "quest_id": 105,
                  "quest_title": "What types of obstructions are present along this sidewalk?",
                  "quest_description": "Select all applicable types of obstructions that are present along this sidewalk.",
                  "quest_type": "MultipleChoice",
                  "quest_tag": "ext:obstruction:type",
                  "quest_answer_dependency": {
                    "question_id": 104,
                    "required_value": "yes"
                  },
                  "quest_answer_choices": [
                    {
                      "value": "bollard",
                      "choice_text": "Bollard",
                      "image_url": "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/main/images/sidewalk/obstruction/bollard_2_square.png"
                    },
                    {
                      "value": "mailbox",
                      "choice_text": "Mailbox",
                      "image_url": "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/main/images/sidewalk/obstruction/mailbox_landscape.png"
                    },
                    {
                      "value": "pole",
                      "choice_text": "Utility Pole",
                      "image_url": "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/main/images/sidewalk/obstruction/utility_2_square.png"
                    },
                    {
                      "value": "waste_bin",
                      "choice_text": "Trash Can",
                      "image_url": "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/main/images/sidewalk/obstruction/waste_bin_square.png"
                    },
                    {
                      "value": "other",
                      "choice_text": "Other obstruction",
                      "choice_follow_up": "Please take a photo of the obstruction."
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
    return LongForm(elementName: quest.elementType, questID: "questId",query: quest.questQuery, action: { tags in
                })
}
