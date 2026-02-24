//
//  PersistenceService.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 24/02/2026.
//

import Foundation

// MARK: - Keys

enum PersistenceKey: String {
    case bookmarkedRepositories = "bookmarked_repositories"
}

// MARK: - Errors

enum PersistenceError: LocalizedError {
    case notFound(PersistenceKey)
    case encodingFailed(Error)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notFound(let key):      
            return "No data found for key: \(key.rawValue)"
        case .encodingFailed(let e):  
            return "Failed to encode: \(e.localizedDescription)"
        case .decodingFailed(let e):
            return "Failed to decode: \(e.localizedDescription)"
        }
    }
}

// MARK: - Protocol

protocol PersistenceServiceProtocol {
    func save<T: Encodable>(_ value: T, forKey key: PersistenceKey) throws
    func load<T: Decodable>(forKey key: PersistenceKey) throws -> T
    func delete(forKey key: PersistenceKey)
}

// MARK: - UserDefaults Implementation

final class UserDefaultsPersistenceService: PersistenceServiceProtocol {
    
    static let shared = UserDefaultsPersistenceService()
    
    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init(
        defaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.defaults = defaults
        self.encoder = encoder
        self.decoder = decoder
    }

    func save<T: Encodable>(_ value: T, forKey key: PersistenceKey) throws {
        do {
            let data = try encoder.encode(value)
            defaults.set(data, forKey: key.rawValue)
        } catch {
            throw PersistenceError.encodingFailed(error)
        }
    }

    func load<T: Decodable>(forKey key: PersistenceKey) throws -> T {
        guard let data = defaults.data(forKey: key.rawValue) else {
            throw PersistenceError.notFound(key)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw PersistenceError.decodingFailed(error)
        }
    }

    func delete(forKey key: PersistenceKey) {
        defaults.removeObject(forKey: key.rawValue)
    }
}
