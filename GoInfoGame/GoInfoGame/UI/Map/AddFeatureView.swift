//
//  AddFeatureView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 06/02/25.
//

import SwiftUI
import CoreLocation

struct FeatureDetail : Identifiable{
    var id = UUID()
    var name: String
    var description: String
    var tags: [String: String]
}

struct AddFeatureView: View {
    @State var tappedCoordinate: CLLocationCoordinate2D
    @Binding var isPresented: Bool
    @State private var selectedFeature: FeatureDetail? = nil
    @State private var isLoading = false
    let features = ["Power Pole:", "Fire hydrant:", "Bench", "Bollard", "Manhole", "Street Lamp", "Waste Basket"]
    
    let featureDetails: [FeatureDetail] = [
        FeatureDetail(name: "Power Pole", description: "A power pole. Often made of wood or metal, they hold power lines.", tags: ["power": "pole"]),
        FeatureDetail(name: "Fire Hydrant", description: "A fire hydrant - where fire response teams connect high-pressure hoses.", tags: ["emergency": "fire_hydrant"]),
        FeatureDetail(name: "Bench", description: "A place for people to sit; allows room for several people.", tags: ["amenity": "bench"]),
        FeatureDetail(name: "Bollard", description: "A solid pillar or pillars made of concrete, metal, plastic, etc., used to control traffic.", tags: ["barrier": "bollard"]),
        FeatureDetail(name: "Manhole", description: "A hole with a cover that allows access to an underground service location, just large enough for a human to climb through.", tags: ["man_made": "manhole"]),
        FeatureDetail(name: "Street Lamp", description: "A raised source of light above a road, which is turned on or lit at night.", tags: ["highway": "street_lamp"]),
        FeatureDetail(name: "Waste Basket", description: "A single small container for depositing garbage that is easily accessible for pedestrians.", tags: ["amenity": "waste_basket"])
    ]
    
    @State var dismissSheet: (String) -> ()

    @State private var alertMessage = ""

    var body: some View {
            ZStack {
                VStack {
                    
                    Text("Select a feature to add")
                        .padding([.top], 15)
                    
                    ScrollView {
                        VStack {
                            ForEach(featureDetails, id: \.id) { feature in
                                Button(action: {
                                    selectedFeature = feature
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(feature.name)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .foregroundColor(.primary)
                                                .font(.custom("Lato-Medium", size: 15)) // Adjust size as needed
                                            
                                            Text(feature.description)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .foregroundColor(Color.gray)
                                                .font(.custom("Lato-Regular", size: 12))
                                                .multilineTextAlignment(.leading)
                                        }
                                        
                                        if selectedFeature?.name == feature.name {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding([.bottom, .leading, .trailing], 10)
                                    .padding([.bottom,.top], 4)
                                    .background(selectedFeature?.name == feature.name ? Color.blue.opacity(0.2) : Color.clear)
                                    .cornerRadius(10)
                                }
                            }
                        }
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
                                .background(selectedFeature?.name != nil ? Color(red: 135/255, green: 62/255, blue: 242/255) : Color.gray)
                                .cornerRadius(20)
                        }
                    }
                    .disabled(selectedFeature?.name == nil)
                    .padding()
                }
            }
    }

    func addFeature() {
        guard let feature = selectedFeature else { return }
        isLoading = true

        Task {
            var powerpole = UserNodesHelper.getPowerPole(
                lat: tappedCoordinate.latitude,
                lon: tappedCoordinate.longitude,
                changeset: 1,
                tags: feature.tags
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
                isPresented = false
                dismissSheet(alertMessage)
            }
        }
    }


}

#Preview {
    AddFeatureView(tappedCoordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), isPresented: .constant(true), dismissSheet: {_ in })
}
