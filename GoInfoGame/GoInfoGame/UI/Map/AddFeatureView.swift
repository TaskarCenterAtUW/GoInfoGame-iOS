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
    
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
            ZStack {
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
        
        if showAlert {
                VStack {
                    Text(alertMessage)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .transition(.opacity)
                .zIndex(1)
            }
            
//            if showAlert {
//                VStack {
//                    Image(systemName: "checkmark.circle.fill")
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(width: 50, height: 50)
//                        .foregroundColor(.green)
//                        .padding(.bottom, 50)
//                    Text(alertMessage)
//                        .foregroundColor(.white)
//                        .padding()
//                        .background(Color.orange)
//                        .cornerRadius(10)
//                }
//                .padding([.all], 50)
//                .background(Color.white)
//                .accessibilityElement(children: .combine)
//                .accessibilityLabel(alertMessage)
//                .onAppear {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                        showAlert = false
//                        isPresented = false
//                    }
//                }
//            }
        
    }

    func addFeature() {
        guard let feature = featureToBeAdded else { return }
        isLoading = true

        Task {
            var powerpole = UserNodesHelper.getPowerPole(
                lat: 17.45971519068802,
                lon: 78.36220464841469,
                changeset: 1,
                tags: ["highway": "street_lamp"]
            )
            
            let result = await DatasyncManager.shared.createNode(node: &powerpole)

            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    alertMessage = "Feature added successfully"
                case .failure:
                    alertMessage = "Something went wrong. Try again"
                }
                
                showAlert = true  // Show the alert
                
                // Dismiss the sheet *after* showing the alert for 1.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showAlert = false  // Hide the alert first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isPresented = false  // Then dismiss the sheet
                    }
                }
            }
        }
    }


}

#Preview {
    AddFeatureView(isPresented: .constant(true))
}
