//
//  GitHubAPIConfig.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 24/02/2026.
//

struct GitHubAPIConfig: APIConfigProtocol {
    private(set) var baseURL: String = "https://api.github.com"
    
    /// Only use the same url for now
    let devBaseURL = "https://api.github.com"
    let stagingBaseURL = "https://api.github.com"
    let prodBaseURL = "https://api.github.com"
    
    /// Headers required by every GitHub API request.
    static let defaultHeaders: [String: String] = [
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28"
    ]
    
    init() {
        baseURL = devBaseURL
    }
    
    mutating func switchTo(_ environment: AppEnvironment) {
        switch environment {
        case .dev:
            baseURL = devBaseURL
        case .staging:
            baseURL = stagingBaseURL
        case .prod:
            baseURL = prodBaseURL
        }
    }
}
