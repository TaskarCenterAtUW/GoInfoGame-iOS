//
//  NetworkMonitor.swift
//  GoInfoGame
//
//  Created by Prashamsa on 29/06/25.
//

import Network
import Combine
// NetworkMonitorHandler
protocol NetworkMonitorHandler {
    var status: Bool { get }
}

// MARK: NetworkMonitor
class NetworkMonitor: NetworkMonitorHandler, ObservableObject {
    @Published var status: Bool = true
    static public let shared: NetworkMonitor = NetworkMonitor()
    private let monitor: NWPathMonitor = NWPathMonitor()
    private let queue: DispatchQueue = DispatchQueue(label: "Monitor")
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
                if path.status == .satisfied {
                    debugPrint("We are connected!")
                    self.status = true
                } else {
                    debugPrint("No connection.")
                    self.status = false
                }
        }
        monitor.start(queue: queue)
    }
}
