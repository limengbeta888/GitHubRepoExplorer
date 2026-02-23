//
//  Repository.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation

struct Repository: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let fork: Bool
    let htmlUrl: String
    let owner: Owner
    let stargazersCount: Int?       // not in /repositories list — fetched separately
    let language: String?           // not in /repositories list — fetched separately
    let forksCount: Int?
    let openIssuesCount: Int?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, fork, owner, language
        case fullName        = "full_name"
        case htmlUrl         = "html_url"
        case stargazersCount = "stargazers_count"
        case forksCount      = "forks_count"
        case openIssuesCount = "open_issues_count"
        case updatedAt       = "updated_at"
    }

    // Merge detail info fetched later
    func merging(detail: RepositoryDetail) -> Repository {
        Repository(
            id: id,
            name: name,
            fullName: fullName,
            description: description,
            fork: fork,
            htmlUrl: htmlUrl,
            owner: owner,
            stargazersCount: detail.stargazersCount,
            language: detail.language,
            forksCount: detail.forksCount,
            openIssuesCount: detail.openIssuesCount,
            updatedAt: detail.updatedAt
        )
    }

    // MARK: Grouping helpers

    var ownerTypeName: String { owner.type ?? "Unknown" }

    var forkStatusName: String { fork ? "Forked" : "Original" }

    var languageGroup: String { language?.isEmpty == false ? language! : "Unknown" }

    var stargazerBand: String {
        guard let stars = stargazersCount else { return "Unknown" }
        switch stars {
        case 0:          return "0 ★"
        case 1..<10:     return "1–9 ★"
        case 10..<100:   return "10–99 ★"
        case 100..<1000: return "100–999 ★"
        default:         return "1 000+ ★"
        }
    }

    var stargazerBandOrder: Int {
        guard let stars = stargazersCount else { return -1 }
        switch stars {
        case 0:          return 0
        case 1..<10:     return 1
        case 10..<100:   return 2
        case 100..<1000: return 3
        default:         return 4
        }
    }
}

// MARK: - Mock Data for Previews
extension Repository {
    static let mock = Repository(
        id: 1,
        name: "ExampleRepo",
        fullName: "octocat/ExampleRepo",
        description: "An example repository for previews",
        fork: false,
        htmlUrl: "https://github.com/octocat/ExampleRepo",
        owner: Owner(
            login: "octocat",
            avatarUrl: "https://avatars.githubusercontent.com/u/1?v=4",
            type: "User"
        ),
        stargazersCount: 123,
        language: "Swift",
        forksCount: 10,
        openIssuesCount: 2,
        updatedAt: "2026-02-23T12:00:00Z"
    )
    
    static let mockList: [Repository] = [
        mock,
        Repository(
            id: 2,
            name: "ExampleRepo2",
            fullName: "octocat/ExampleRepo2",
            description: "An example repository for previews",
            fork: false,
            htmlUrl: "https://github.com/octocat/ExampleRepo2",
            owner: Owner(
                login: "octocat",
                avatarUrl: "https://avatars.githubusercontent.com/u/1?v=4",
                type: "User"
            ),
            stargazersCount: 123,
            language: "Swift",
            forksCount: 10,
            openIssuesCount: 2,
            updatedAt: "2026-02-23T12:00:00Z"
        )
    ]
}
