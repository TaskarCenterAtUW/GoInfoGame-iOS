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
    @Environment(\.presentationMode) var presentationMode
    /// A binding (not a one-time value) so it keeps reflecting the pin's position as
    /// the user drags the map underneath it while this sheet stays open.
    @Binding var tappedCoordinate: CLLocationCoordinate2D
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
                VStack(alignment: .leading) {
                    
                    HStack {
                        Text("Select a feature to add")
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
                    
                    ScrollView {
                        VStack {
                            ForEach(featureDetails, id: \.id) { feature in
                                Button(action: {
                                    selectedFeature = feature
                                }) {
                                    HStack(spacing: 5) {
                                        VStack(alignment: .leading) {
                                            Text(feature.name)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .foregroundColor(Asset.Colors._42526ETextFieldText.swiftUIColor)
                                                .font(FontFamily.Lato.bold.swiftUIFont(size: 16))
                                            
                                            Text(feature.description)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .foregroundColor(Asset.Colors._83879BTextFiledTitle.swiftUIColor)
                                                .font(FontFamily.Lato.regular.swiftUIFont(size: 12))
                                                .multilineTextAlignment(.leading)
                                        }
                                        
                                        if selectedFeature?.name == feature.name {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Asset.Colors.d74BA827Pink.swiftUIColor)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundColor(Asset.Colors._83879BTextFiledTitle.swiftUIColor)
                                        }
                                    }
                                    .padding()
                                    .background(selectedFeature?.name == feature.name ? Asset.Colors.d74BA827Pink.swiftUIColor.opacity(0.1) : Color.clear)
                                    .border(Asset.Colors.ddddddLine.swiftUIColor, width: 1)
                                    .cornerRadius(5)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            Task {
                                do {
                                    await addFeature()
                                } catch {
                                    print("Error adding feature: \(error)")
                                }
                            }
                        }) {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Add feature")
                                    .font(FontFamily.Lato.bold.swiftUIFont(size: 20))
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(width: 155, height: 46)
                                    .background(selectedFeature?.name != nil ? Asset.Colors.huskyPurple.swiftUIColor : Color.gray)
                                    .cornerRadius(23)
                            }
                        }
                        .disabled(selectedFeature?.name == nil)
                        .padding()
                        
                        Spacer()
                    }
                }
            }
    }

    func addFeature() async {
        guard let feature = selectedFeature else { return }
        isLoading = true

        let powerpole = UserNodesHelper.getPowerPole(
            lat: tappedCoordinate.latitude,
            lon: tappedCoordinate.longitude,
            changeset: 1,
            tags: feature.tags
        )

        do {
            let _ = try await DatasyncManager.shared.createNode(node: powerpole)
            alertMessage = "Feature added successfully"
        } catch {
            print("ERROR IN CREATING FEATURE ---->>> \(error)")
            alertMessage = "Something went wrong. Try again"
        }

        await MainActor.run {
            isLoading = false
            isPresented = false
            dismissSheet(alertMessage)
        }
    }
}

#Preview {
    AddFeatureView(tappedCoordinate: .constant(CLLocationCoordinate2D(latitude: 0, longitude: 0)), isPresented: .constant(true), dismissSheet: {_ in })
}
