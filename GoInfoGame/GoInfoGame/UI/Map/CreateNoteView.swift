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
    @State private var alertMessage = ""
    @StateObject private var noteViewModel = NotesViewModel()
    
    @State var dismissSheet: (String) -> ()
    
    var body: some View {
        ZStack {
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
                
                HStack {
                    Spacer()
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
                                .font(FontFamily.Lato.bold.swiftUIFont(size: 20))
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 156, height: 46)
                                .background(noteText != "" ? Asset.Colors.huskyPurple.swiftUIColor : Color.gray)
                                .cornerRadius(23)
                        }
                    }
                    .disabled(noteText == "")
                    Spacer()
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
