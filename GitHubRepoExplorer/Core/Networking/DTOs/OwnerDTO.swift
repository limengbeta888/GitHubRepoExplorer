//
//  OwnerDTO.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 10/06/2026.
//

struct OwnerDTO: Codable {
    let login: String
    let avatarUrl: String?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case login
        case type
        case avatarUrl = "avatar_url"
    }

    func toDomain() -> Owner {
        Owner(login: login, avatarUrl: avatarUrl, type: type)
    }
}
