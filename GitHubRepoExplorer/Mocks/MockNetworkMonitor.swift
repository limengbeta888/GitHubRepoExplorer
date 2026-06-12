//
//  MockNetworkMonitor.swift
//  GitHubRepoExplorer
//

import Observation
import Foundation

@Observable
final class MockNetworkMonitor: NetworkMonitorProtocol {
    var isConnected: Bool = true
    
    init(isConnected: Bool = true) {
        self.isConnected = isConnected
    }
}
