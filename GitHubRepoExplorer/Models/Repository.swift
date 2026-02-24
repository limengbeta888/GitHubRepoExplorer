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

    // Absent from /repositories list — populated by fetching /repos/{owner}/{repo}
    let stargazersCount: Int?
    let language: String?
    let forksCount: Int?
    let openIssuesCount: Int?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case fork
        case owner
        case language
        case fullName        = "full_name"
        case htmlUrl         = "html_url"
        case stargazersCount = "stargazers_count"
        case forksCount      = "forks_count"
        case openIssuesCount = "open_issues_count"
        case updatedAt       = "updated_at"
    }

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
}

// MARK: - Grouping helpers

extension Repository {
    var ownerTypeName: String  {
        owner.type ?? "Unknown"
    }
    
    var forkStatusName: String {
        fork ? "Forked" : "Original"
    }
    
    var languageGroup: String  {
        language?.isEmpty == false ? language! : "Unknown"
    }

    var stargazerBand: String {
        guard let stars = stargazersCount else { return "Unknown" }
        
        switch stars {
        case 0:          
            return "0 ★"
        case 1 ..< 10:
            return "1–9 ★"
        case 10 ..< 100:
            return "10–99 ★"
        case 100 ..< 1000:
            return "100–999 ★"
        default:         
            return "1000+ ★"
        }
    }

    var stargazerBandOrder: Int {
        guard let stars = stargazersCount else { return -1 }
        
        switch stars {
        case 0:
            return 0
        case 1 ..< 10:
            return 1
        case 10 ..< 100:
            return 2
        case 100 ..< 1000:
            return 3
        default:
            return 4
        }
    }
}
