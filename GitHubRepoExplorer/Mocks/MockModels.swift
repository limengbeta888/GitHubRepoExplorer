//
//  MockModels.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 24/02/2026.
//

// MARK: - MockOwner

@MainActor
extension Owner {
    static let mockUser = Owner(login: "mojombo",
                                avatarUrl: "https://avatars.githubusercontent.com/u/1?v=4",
                                type: "User")
    
    static let mockOrg  = Owner(login: "apple",
                                avatarUrl: "https://avatars.githubusercontent.com/u/10639145?v=4",
                                type: "Organization")
}

// MARK: - MockRepository

@MainActor
extension Repository {
    static let mockOriginal = Repository(
        id: 28,
        name: "god",
        fullName: "mojombo/god",
        description: "Ruby process monitor",
        fork: false,
        htmlUrl: "https://github.com/mojombo/god",
        owner: .mockUser,
        stargazersCount: nil,
        language: nil,
        forksCount: nil,
        openIssuesCount: nil,
        updatedAt: nil
    )
    
    static let mockFork = Repository(
        id: 42,
        name: "rails",
        fullName: "dhh/rails",
        description: "Ruby on Rails fork",
        fork: true,
        htmlUrl: "https://github.com/dhh/rails",
        owner: .mockUser,
        stargazersCount: 312,
        language: "Ruby",
        forksCount: 14,
        openIssuesCount: 3,
        updatedAt: "2024-03-15T10:22:00Z"
    )
    
    static let mockOrgRepo = Repository(
        id: 1001,
        name: "swift",
        fullName: "apple/swift",
        description: "The Swift Programming Language",
        fork: false,
        htmlUrl: "https://github.com/apple/swift",
        owner: .mockOrg,
        stargazersCount: 65_000,
        language: "C++",
        forksCount: 10_500,
        openIssuesCount: 7_200,
        updatedAt: "2024-06-01T08:00:00Z"
    )
    
    static let mockZeroStars = Repository(
        id: 100,
        name: "empty-project",
        fullName: "newbie/empty-project",
        description: "Just getting started",
        fork: false,
        htmlUrl: "https://github.com/newbie/empty-project",
        owner: Owner(login: "newbie", avatarUrl: nil, type: "User"),
        stargazersCount: 0,
        language: "Swift",
        forksCount: 0,
        openIssuesCount: 1,
        updatedAt: nil
    )
    
    static let mockStars1to9 = Repository(
        id: 201,
        name: "tiny-lib",
        fullName: "someone/tiny-lib",
        description: "A small utility",
        fork: false,
        htmlUrl: "https://github.com/someone/tiny-lib",
        owner: Owner(login: "someone", avatarUrl: nil, type: "User"),
        stargazersCount: 7,
        language: "Go",
        forksCount: 1,
        openIssuesCount: 0,
        updatedAt: nil
    )
    
    static let mockStars10to99 = Repository(
        id: 202,
        name: "cool-tool",
        fullName: "someone/cool-tool",
        description: "A moderately popular tool",
        fork: false,
        htmlUrl: "https://github.com/someone/cool-tool",
        owner: Owner(login: "someone", avatarUrl: nil, type: "User"),
        stargazersCount: 55,
        language: "Python",
        forksCount: 8,
        openIssuesCount: 2,
        updatedAt: nil
    )
    
    static let mockStars100to999 = Repository(
        id: 203,
        name: "popular-lib",
        fullName: "org/popular-lib",
        description: nil,
        fork: false,
        htmlUrl: "https://github.com/org/popular-lib",
        owner: Owner(login: "org", avatarUrl: nil, type: "Organization"),
        stargazersCount: 450,
        language: "TypeScript",
        forksCount: 60,
        openIssuesCount: 12,
        updatedAt: nil
    )
    
    static let mockStars1000plus = Repository(
        id: 204,
        name: "mega-framework",
        fullName: "bigco/mega-framework",
        description: "Used by millions",
        fork: false,
        htmlUrl: "https://github.com/bigco/mega-framework",
        owner: Owner(login: "bigco", avatarUrl: nil, type: "Organization"),
        stargazersCount: 24_000,
        language: "Rust",
        forksCount: 3_100,
        openIssuesCount: 540,
        updatedAt: nil
    )

    static let allMocks: [Repository] = [
        .mockOriginal, .mockFork, .mockOrgRepo,
        .mockZeroStars, .mockStars1to9, .mockStars10to99,
        .mockStars100to999, .mockStars1000plus
    ]
}

// MARK: - MockRepositoryDetail

@MainActor
extension RepositoryDetail {
    static let mockBasic = RepositoryDetail(
        stargazersCount: 1_234, language: "Ruby",
        forksCount: 89, openIssuesCount: 14, updatedAt: "2024-04-10T12:00:00Z"
    )
    static let mockHighTraffic = RepositoryDetail(
        stargazersCount: 98_000, language: "C++",
        forksCount: 15_000, openIssuesCount: 8_200, updatedAt: "2024-06-15T09:45:00Z"
    )
    static let mockNoLanguage = RepositoryDetail(
        stargazersCount: 5, language: nil,
        forksCount: 0, openIssuesCount: 0, updatedAt: nil
    )
}
