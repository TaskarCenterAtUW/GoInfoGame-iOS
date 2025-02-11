//
//  CreateNoteView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 11/02/25.
//

import SwiftUI

struct CreateNoteView: View {
    
    @State private var noteText = ""
    @State private var showNotesBox = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextEditor(text: $noteText)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal, 20)
            
            HStack {
                Button("Submit") {
                    submitNote()
                    showNotesBox = false
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal, 20)
                
                Button("Cancel") {
                    showNotesBox = false
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 10)
    }
    
    func submitNote() {
        print("Note to be submitted: \(noteText)")
    }
}


#Preview {
    CreateNoteView()
}
