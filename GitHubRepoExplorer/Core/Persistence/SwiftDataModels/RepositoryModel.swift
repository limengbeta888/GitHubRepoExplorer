//
//  RepositoryModel.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 24/02/2026.
//

import SwiftData
import Foundation

@Model
final class RepositoryModel {

    @Attribute(.unique) var id: Int
    var name: String
    var fullName: String
    var repoDescription: String?
    var fork: Bool
    var htmlUrl: String
    var ownerLogin: String
    var ownerAvatarUrl: String?
    var ownerType: String?
    var stargazersCount: Int?
    var language: String?
    var forksCount: Int?
    var openIssuesCount: Int?
    var updatedAt: String?
    var insertedAt: Date

    init(from repo: Repository) {
        self.id = repo.id
        self.name = repo.name
        self.fullName = repo.fullName
        self.repoDescription = repo.description
        self.fork = repo.fork
        self.htmlUrl = repo.htmlUrl
        self.ownerLogin = repo.owner.login
        self.ownerAvatarUrl = repo.owner.avatarUrl
        self.ownerType = repo.owner.type
        self.stargazersCount = repo.stargazersCount
        self.language = repo.language
        self.forksCount = repo.forksCount
        self.openIssuesCount = repo.openIssuesCount
        self.updatedAt = repo.updatedAt
        self.insertedAt = Date()
    }

    func toRepository() -> Repository {
        Repository(
            id: id,
            name: name,
            fullName: fullName,
            description: repoDescription,
            fork: fork,
            htmlUrl: htmlUrl,
            owner: Owner(login: ownerLogin, avatarUrl: ownerAvatarUrl, type: ownerType),
            stargazersCount: stargazersCount,
            language: language,
            forksCount: forksCount,
            openIssuesCount: openIssuesCount,
            updatedAt: updatedAt
        )
    }
}
