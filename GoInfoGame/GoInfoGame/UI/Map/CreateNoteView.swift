//
//  CreateNoteView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 11/02/25.
//

import SwiftUI
import CoreLocation

struct CreateNoteView: View {
    
    @State var coordinates: CLLocationCoordinate2D
    @State private var noteText = ""
    @Binding var showNotesBox: Bool
    @State private var alertMessage = ""
    @StateObject private var noteViewModel = NotesViewModel()
    
    @State var dismissSheet: (String) -> ()
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 10) {
                TextEditor(text: $noteText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                
                HStack {
                    Button(action: {
                        Task {
                            do {
                                try await submitNote()
                            } catch {
                                print("Error adding feature: \(error)")
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
                            .background(Color.red)
                            .cornerRadius(9)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 10)
            
            if noteViewModel.isLoading {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
               ActivityView(activityText: "Submitting Note")
            }
        }
    }
    
    func submitNote() async throws {
        print("Note to be submitted: \(noteText)")
        
        do {
          let notesResult = try await noteViewModel.createNote(note: noteText, lat: coordinates.latitude, long: coordinates.longitude)
            
            if notesResult {
                print("Notes composed successfully")
                alertMessage = "Note submitted successfully"
                dismissSheet(alertMessage)
                
            }
        } catch {
            alertMessage = "Error submitting note: \(error.localizedDescription)"
           
            dismissSheet(alertMessage)
        }
        
        await MainActor.run {
            noteViewModel.isLoading = false
            showNotesBox = false
            dismissSheet(alertMessage)
        }
    }
}


#Preview {
    CreateNoteView(coordinates: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), showNotesBox: .constant(true), dismissSheet: {_ in })
}
