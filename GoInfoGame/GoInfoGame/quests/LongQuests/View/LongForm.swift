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
    
    var elementType: LongFormElementType?
    
    var questID: String?
    
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

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                VStack {
                    HStack {
                        Text("\(elementHeading())")
                            .font(.custom("Lato-Bold", size: 16))
                            .padding([.leading], 20)
                        Text("ID: \(questID ?? "0")")
                            .font(.custom("Lato-Regular", size: 13))
                            .padding([.leading], 20)
                    }
                    .padding(EdgeInsets(top: 20, leading: 20, bottom: 10, trailing: 20))
                    LongFormDismissButtonView {
                        withAnimation {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .padding([.trailing], 20)
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
    
    func elementHeading() -> String {
        switch elementType {
        case .sidewalk:
            return "Sidewalks"
        case .kerb:
            return "Curb"
        case .crossing:
            return "Crossings"
        case nil:
            return ""
        }
    }
    
    func questsForLongForm() -> [LongQuest]? {
        var longQuest: [LongQuest]?
        
        switch elementType {
        case .sidewalk:
            longQuest = QuestsRepository.shared.sideWalkLongQuestModel?.quests
        case .kerb:
            longQuest = QuestsRepository.shared.kerbLongQuestModel?.quests
        case .crossing:
            longQuest = QuestsRepository.shared.crossingsLongQuestModel?.quests
        case .none:
            print("None")
        }
        return longQuest
    }
}

#Preview {
    LongForm()
}


enum LongFormElementType {
    case sidewalk,kerb,crossing
}
