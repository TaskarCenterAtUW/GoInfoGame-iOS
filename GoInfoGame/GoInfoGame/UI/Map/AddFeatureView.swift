//
//  AddFeatureView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 06/02/25.
//

import SwiftUI


struct AddFeatureView: View {
    @Binding var isPresented: Bool
    @State private var featureToBeAdded: String? = nil
    @State private var isLoading = false
    let features = ["Power Pole:", "Fire hydrant:", "Bench", "Bollard", "Manhole", "Street Lamp", "Waste Basket"]

    var body: some View {
        NavigationView {
            VStack {
                
                Text("Select a feature to add")
                    .padding([.top], 15)
                
                ScrollView {
                    VStack {
                        ForEach(features, id: \.self) { feature in
                            Button(action: { featureToBeAdded = feature }) {
                                HStack {
                                    Text(feature)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .foregroundColor(.primary)
                                    if featureToBeAdded == feature {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(featureToBeAdded == feature ? Color.blue.opacity(0.2) : Color.clear)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                Button(action: addFeature) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Add feature")
                            .font(.custom("Lato-Bold", size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 200, height: 40)
                            .background(featureToBeAdded != nil ? Color(red: 135/255, green: 62/255, blue: 242/255) : Color.gray)
                            .cornerRadius(20)
                    }
                }
                .disabled(featureToBeAdded == nil)
                .padding()
            }
        }
    }

    func addFeature() {
        guard let feature = featureToBeAdded else { return }
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            print("Feature added: \(feature)")
            isPresented = false
        }
    }
}

#Preview {
    AddFeatureView(isPresented: .constant(true))
}
