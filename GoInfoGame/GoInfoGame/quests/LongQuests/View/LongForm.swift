//
//  SidewalkLongForm.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 22/07/24.
//

import SwiftUI


struct LongForm: View, QuestForm {
    
    @State private var selectedAnswers: [UUID: UUID] = [:]
    
    @ObservedObject private var viewModel = LongFormViewModel()
        
    var elementName: String?
    
    var questID: String?
    
    var query: String?
    
    var action: (([String:String]) -> Void)?
    
    typealias AnswerClass = [String:String]
    
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

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                    HStack {
                        Text(elementName ?? "")
                            .font(.custom("Lato-Bold", size: 16))
                        Spacer()
                        Button("Hide this") {
                            withAnimation {
                                MapViewPublisher.shared.dismissSheet.send(.hideElement(questID ?? "0", elementName ?? ""))
                                presentationMode.wrappedValue.dismiss()
                            }
                            
                        }
                    }
                
                    .padding(EdgeInsets(top: 20, leading: 20, bottom: 10, trailing: 20))
                
                Text("ID: \(questID ?? "0")")
                    .font(.custom("Lato-Regular", size: 13))
                    .padding([.leading], 20)
                
                HStack {
                    Button {
                        showNotesBox = true
                    } label: {
                        Text(" Compose Note")
                            .font(.custom("Lato-Bold", size: 15))
                    }
                    .padding(EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 20))
                    
                    
                    LongFormDismissButtonView {
                        withAnimation {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .padding([.trailing], 20)
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
                            .border(Color(red: 135/255, green: 62/255, blue: 242/255))
                        
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
                                        .background(noteText != "" ? Color(red: 135/255, green: 62/255, blue: 242/255) : Color.gray)
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
                                    .background(Color.red)
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
                                    LongQuestView(selectedAnswers: $selectedAnswers, quest: quest, onChoiceSelected: { selectedAnswerChoice in
                                        viewModel.updateAnswers(quest: quest, selectedAnswerChoice: selectedAnswerChoice)
                                    }, uploadPhoto:  { result in
                                        if result {
                                            isCameraPresented = true
                                        }
                                    },currentAnswer: $viewModel
                                        .answersToBeSubmitted[quest.questTag])
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
                                Button(action: {
                                    if !viewModel.answersToBeSubmitted.isEmpty {
                                        if let action = action {
                                            if !uploadedPhotos.isEmpty {
                                                viewModel.answersToBeSubmitted["ext:kartaview_url"] = uploadedPhotos.joined(separator: ", ")
                                            }
                                         
                                              action(viewModel.answersToBeSubmitted)
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
                                        .background(Color(red: 135/255, green: 62/255, blue: 242/255))
                                        .cornerRadius(20)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Text("No Quests available")
                        }
                    }
                }
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
        print("Note to be submitted: \(noteText)")
        
        do {
            let notesResult = try await noteViewModel.createNote(note: noteText, lat: 0.0, long: 0.0)
            
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
}

#Preview {
    LongForm()
}
