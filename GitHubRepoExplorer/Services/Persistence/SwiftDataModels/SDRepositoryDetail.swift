//
//  RepositoryDetailModel.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 10/06/2026.
//

import SwiftData
import Foundation

@Model
final class SDRepositoryDetail {
    @Attribute(.unique) var fullName: String
    var stargazersCount: Int?
    var language: String?
    var forksCount: Int?
    var openIssuesCount: Int?
    var updatedAt: String?
    var lastFetchedAt: Date

    init(fullName: String, detail: RepositoryDetail) {
        self.fullName = fullName
        self.stargazersCount = detail.stargazersCount
        self.language = detail.language
        self.forksCount = detail.forksCount
        self.openIssuesCount = detail.openIssuesCount
        self.updatedAt = detail.updatedAt
        self.lastFetchedAt = Date()
    }

    func toDetail() -> RepositoryDetail {
        RepositoryDetail(
            stargazersCount: stargazersCount,
            language: language,
            forksCount: forksCount,
            openIssuesCount: openIssuesCount,
            updatedAt: updatedAt
        )
    }
}
