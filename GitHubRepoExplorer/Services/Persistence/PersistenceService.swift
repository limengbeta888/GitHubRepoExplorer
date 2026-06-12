//
//  PersistenceService.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 10/06/2026.
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
        case .notFound:
            return "Record not found."
            
        case .saveFailed(let e):
            return "Failed to save: \(e.localizedDescription)"
            
        case .loadFailed(let e):
            return "Failed to load: \(e.localizedDescription)"
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

    // Cached Details
    func saveDetail(_ detail: RepositoryDetail, for fullName: String) throws
    func fetchDetail(for fullName: String, maxAge: TimeInterval) throws -> RepositoryDetail?
}

// MARK: - Implementation

final class PersistenceService: PersistenceServiceProtocol {
    static let shared = PersistenceService()

    private let context: ModelContext

    private init() {
        let schema = Schema([SDRepository.self, SDRepositoryDetail.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try! ModelContainer(for: schema, configurations: config)
        self.context = ModelContext(container)
    }

    private init(container: ModelContainer) {
        self.context = ModelContext(container)
    }
    
    func saveDetail(_ detail: RepositoryDetail, for fullName: String) throws {
        if let existing = try fetchDetailModel(fullName: fullName) {
            existing.stargazersCount = detail.stargazersCount
            existing.language = detail.language
            existing.forksCount = detail.forksCount
            existing.openIssuesCount = detail.openIssuesCount
            existing.updatedAt = detail.updatedAt
            existing.lastFetchedAt = Date()
        } else {
            context.insert(SDRepositoryDetail(fullName: fullName, detail: detail))
        }
        try save()
    }

    func fetchDetail(for fullName: String, maxAge: TimeInterval) throws -> RepositoryDetail? {
        guard let model = try fetchDetailModel(fullName: fullName) else { return nil }

        let age = Date().timeIntervalSince(model.lastFetchedAt)
        if age > maxAge {
            return nil // Expired
        }

        return model.toDetail()
    }

    // MARK: - Private

    private func fetchDetailModel(fullName: String) throws -> SDRepositoryDetail? {
        var descriptor = FetchDescriptor<SDRepositoryDetail>(
            predicate: #Predicate { $0.fullName == fullName }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    // MARK: - PersistenceServiceProtocol

    func add(_ repo: Repository) throws {
        context.insert(SDRepository(from: repo))
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
        model.language        = repo.language
        model.forksCount      = repo.forksCount
        model.openIssuesCount = repo.openIssuesCount
        model.updatedAt       = repo.updatedAt
        try save()
    }

    func loadAllRepos() throws -> [Repository] {
        let descriptor = FetchDescriptor<SDRepository>(
            sortBy: [SortDescriptor(\.insertedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map { $0.toRepository() }
    }

    func deleteAllRepos() throws {
        try context.delete(model: SDRepository.self)
        try save()
    }

    // MARK: - Private

    private func fetchModel(id: Int) throws -> SDRepository? {
        var descriptor = FetchDescriptor<SDRepository>(
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
        let schema = Schema([SDRepository.self, SDRepositoryDetail.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        return PersistenceService(container: container)
    }
}
