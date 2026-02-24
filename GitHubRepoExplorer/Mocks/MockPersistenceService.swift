//
//  MockPersistenceService.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 24/02/2026.
//

import Foundation

/// In-memory persistence for unit tests and previews.
/// No UserDefaults involved — fully isolated and synchronous.
final class MockPersistenceService: PersistenceServiceProtocol {

    private var storage: [String: Data] = [:]
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func save<T: Encodable>(_ value: T, forKey key: PersistenceKey) throws {
        storage[key.rawValue] = try encoder.encode(value)
    }

    func load<T: Decodable>(forKey key: PersistenceKey) throws -> T {
        guard let data = storage[key.rawValue] else {
            throw PersistenceError.notFound(key)
        }
        return try decoder.decode(T.self, from: data)
    }

    func delete(forKey key: PersistenceKey) {
        storage.removeValue(forKey: key.rawValue)
    }
}
