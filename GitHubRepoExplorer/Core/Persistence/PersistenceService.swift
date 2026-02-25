//
//  PersistenceService.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 24/02/2026.
//

import Foundation
import SwiftData

// MARK: - Errors

enum PersistenceError: LocalizedError {
    case notFound
    case saveFailed(Error)
    case loadFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notFound:           return "Record not found."
        case .saveFailed(let e):  return "Failed to save: \(e.localizedDescription)"
        case .loadFailed(let e):  return "Failed to load: \(e.localizedDescription)"
        }
    }
}

// MARK: - Protocol

protocol PersistenceServiceProtocol {
    func add(_ repo: Repository) throws
    func remove(_ repo: Repository) throws
    func update(_ repo: Repository) throws
    func loadAllRepos() throws -> [Repository]
    func deleteAllRepos() throws
}

// MARK: - Implementation

final class PersistenceService: PersistenceServiceProtocol {
    static let shared = PersistenceService()
    
    private let context: ModelContext

    // MARK: - Init

    private init() {
        let schema = Schema([RepositoryModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try! ModelContainer(for: schema, configurations: config)
        self.context = ModelContext(container)
    }

    init(container: ModelContainer) {
        self.context = ModelContext(container)
    }

    // MARK: - PersistenceServiceProtocol

    func add(_ repo: Repository) throws {
        context.insert(RepositoryModel(from: repo))
        try save()
    }

    func remove(_ repo: Repository) throws {
        guard let model = try fetchModel(id: repo.id) else { return }
        
        context.delete(model)
        
        try save()
    }

    func update(_ repo: Repository) throws {
        guard let model = try fetchModel(id: repo.id) else { return }
        
        model.stargazersCount = repo.stargazersCount
        model.language = repo.language
        model.forksCount = repo.forksCount
        model.openIssuesCount = repo.openIssuesCount
        model.updatedAt = repo.updatedAt
        
        try save()
    }

    func loadAllRepos() throws -> [Repository] {
        let descriptor = FetchDescriptor<RepositoryModel>(
            sortBy: [SortDescriptor(\.insertedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map { $0.toRepository() }
    }

    func deleteAllRepos() throws {
        try context.delete(model: RepositoryModel.self)
        try save()
    }

    // MARK: - Private

    private func fetchModel(id: Int) throws -> RepositoryModel? {
        var descriptor = FetchDescriptor<RepositoryModel>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func save() throws {
        do {
            try context.save()
        } catch {
            throw PersistenceError.saveFailed(error)
        }
    }
}

// MARK: - In-memory variant for tests and previews

extension PersistenceService {
    static func inMemory() -> PersistenceService {
        let schema = Schema([RepositoryModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        return PersistenceService(container: container)
    }
}
