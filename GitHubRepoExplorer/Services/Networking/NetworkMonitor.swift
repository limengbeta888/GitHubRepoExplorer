//
//  NetworkMonitor.swift
//  GitHubRepoExplorer
//

import Network
import Observation

protocol NetworkMonitorProtocol: Sendable {
    var isConnected: Bool { get }
}

@Observable
final class NetworkMonitor: NetworkMonitorProtocol {
    static let shared = NetworkMonitor()
    
    private(set) var isConnected: Bool = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}
