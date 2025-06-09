

# GoInfoGame-iOS

GoInfoGame is a volunteerism app that leverages crowdsourcing to gather critical pedestrian and accessibility information. Participants engage in quests—simple surveys aimed at collecting missing labels in pedestrian data—to improve the accessibility of public spaces. 

## Features

- **Crowdsourced Data Collection**: Provide information on accessibility features such as sidewalks, ramps, crossings, and more.
- **Interactive Gameplay**: Participate in quests to gather data through an engaging user interface.
- **Impactful Contribution**: Support the creation of more accessible public spaces by sharing real-world insights.
- **Community Collaboration**: Collaborate with other users to improve the accuracy and coverage of accessibility data.
- **Offline Support**: Complete quests even without an internet connection, with data syncing once reconnected.


## Prerequisites

Before compiling the app, ensure you have the following installed:

- **Xcode**: Version 15.0 or later.
  - Download it from the [Mac App Store](https://apps.apple.com/us/app/xcode/id497799835).
- **CocoaPods**: For managing dependencies.
  - Install using the command:
    ```bash
    sudo gem install cocoapods
    ```

## Setting Up the Project

1. Install the necessary dependencies using CocoaPods:
    ```bash
    pod install
    ```
2. Open the project in Xcode using the `.xcworkspace` file:
    ```bash
    open GoInfoGame.xcworkspace
    ```

## Tech Stack
- **Language** : Swift
- **Framework** : SwiftUI
- **Networking** : URLSession
- **Data Management** : RealmSwift
- **Dependency Management** : Cocoapods

## Project Structure

The project follows a typical **SwiftUI MVVM (Model-View-ViewModel)** architecture:

-  **Models**  : Contains data models representing application data.  

- **Views**  : SwiftUI views for displaying UI components.  

-  **ViewModels**  : Handles business logic and state management.  

- **Services**  : Manages network calls and API interactions.  

-  **Utilities**  : Includes common functions, constants, and extensions.  

##  **Key Components**  

- **Quest Management:** Handles the logic for displaying and tracking user quests.  
- **Map Integration:** Uses **MapKit** to show location data.  
- **APIManager:** Manages all API calls and responses.  
- **Data Persistence:** **RealmSwift** stores offline data for later submission.


## API Integration

- APIs are managed using [`APIManager`](GoInfoGame/GoInfoGame/Network/ApiManager.swift).
- Endpoints and HTTP methods are defined in [`APIEndpoint`](GoInfoGame/GoInfoGame/Network/APIEndPoint.swift).
- API responses are parsed using `Codable` models for seamless data handling.

## Performing API Requests

The project uses a generic `performRequest` function to efficiently handle API requests.

Example API  call:
  ```
  APIManager.shared.performRequest(endpoint: .getQuests) { result in
    switch result {
    case .success(let quests):
        print("Received quests: \(quests)")
    case .failure(let error):
        print("Error: \(error)")
    }
  }

  ```

###  **Parameters**

- **endpoint**: An `APIEndpoint` representing the API path and parameters.
- **setupType**: Specifies the setup system (workspace, OSM, TDEI, Kartaview ).
- **modelType**: The expected response model conforming to `Decodable`.
- **useJSON**: A boolean indicating whether to send or expect JSON data (default: `true`).
- **completion**: A closure returning a `Result` with the decoded model or an error.


##  **API Environment Configuration**  

The [`APIEnvironment`](GoInfoGame/GoInfoGame/Network/APIEnvironment.swift) enum manages environment-specific configurations, defining base URLs for services across development, staging, and production environments. It helps the app connect to different systems based on the environment.  


###  **Systems Overview**  

| System                                      | Variable                           | Purpose                                           | Service URL Usage                                   |
|---------------------------------------------|-----------------------------------|----------------------------------------------------|-----------------------------------------------------|
| **Workspace**                               | `workspaceBaseURL`                | Manages user-contributed data and tasks.          | Connects to the Sidewalks project backend.         |
| **OSM (OpenStreetMap)**                    | `osmBaseURL`                      | Handles geospatial data operations.               | Used for fetching and submitting map data.         |
| **TDEI (Transportation Data Exchange Initiative)** | `loginBaseURL`, `userProfileBaseURL` | Provides user management, login, and data exchange. | Handles authentication and user info.              |
| **Kartaview**                               | `kartaviewBaseURL`                | Displays street-level imagery.                    | Pushes image data to KartaView.                    |




###  **Simulating Location in the iOS Simulator**  

In your project, a `samplepoint.gpx` file is already included for simulating location data in the iOS simulator.  

To simulate a specific location:  

1. **Update Coordinates**:  
    - Open the `samplepoint.gpx` file.  
    - Locate the following line:  
    ```xml
    <wpt lat="17.438381576598886" lon="78.34873578711657">
    ```
    - Update the `lat` (latitude) and `lon` (longitude) values to your desired location.  

2. **Run the Simulation**:  
    - Launch your app in the iOS simulator using Xcode.  
    - In the Xcode **Debug Area**, find the **Location** button.  
    - Click the **Location** button and select `samplepoint.gpx`.  

The simulator will now use the updated coordinates as the current location.

###  **Logging into the App**  

To log into the app, you will need valid credentials.  

- Credentials can be provided upon request.  
- Please email your request to **achyutm@gaussiansolutions.com**.  

Once you receive your credentials, you can proceed to the login screen and access the app.  



---
