//
//  TestHelpers.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 12/06/2026.
//

import Testing

class TestHelpers {
    static let shared = TestHelpers()
    private init() {}
    
    func waitForCondition(
        timeout: Duration = .seconds(2),
        condition: @MainActor () -> Bool
    ) async throws {
        let deadline = ContinuousClock().now + timeout
        while await !condition() {
            if ContinuousClock().now >= deadline {
                Issue.record("Timed out waiting for condition")
                return
            }
            try await Task.sleep(for: .milliseconds(50))
        }
    }
}
