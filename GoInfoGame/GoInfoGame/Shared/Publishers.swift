//
//  Publishers.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 08/06/25.
//

import Foundation
import Combine

public class MapViewPublisher: ObservableObject {
    public let dismissSheet = PassthroughSubject<SheetDismissalScenario, Never>()
    static let shared = MapViewPublisher()
    private init() {}
}

public class QuestsPublisher: ObservableObject {
    public let refreshQuest = PassthroughSubject<String, Never>()
    static let shared = QuestsPublisher()
    private init() {}
}

public enum SheetDismissalScenario {
    case dismissed
    case submitted(String)
    case syncing
    case synced
    case failed(String)
    case hideElement(String, String)
    case undoDone(String)
}

//TODO: Move to a new file
class ContextualInfo: ObservableObject {
    static let shared = ContextualInfo()
    
    @Published var info: String = "Contextual info appears here"
    
    private init() {}
}


