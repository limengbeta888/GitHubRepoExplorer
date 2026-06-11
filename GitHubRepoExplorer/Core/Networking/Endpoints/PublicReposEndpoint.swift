//
//  PublicReposEndpoint.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 10/06/2026.
//

import Foundation

enum PublicReposEndpoint: Endpoint {

    /// Initial or subsequent page of the public repository list.
    case repositories
    case nextRepositories(URL)
    /// Detail for a single repository, e.g. `/repos/mojombo/god`.
    case repositoryDetail(fullName: String)

    // MARK: - Constants
    
    private var baseURL: String { "https://api.github.com" }
    
    // MARK: - Endpoint

    var url: URL {
        get throws {
            switch self {
            case .repositories:
                return try PathEndpointURL(baseURL: baseURL, path: "/repositories").resolve()

            case .nextRepositories(let absoluteURL):
                return absoluteURL

            case .repositoryDetail(let fullName):
                return try PathEndpointURL(baseURL: baseURL, path: "/repos/\(fullName)").resolve()
            }
        }
    }

    var headers: [String: String]? {
        [
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28"
        ]
    }
}

// MARK: - Helper: composing a URL from base + path

private struct PathEndpointURL {
    let baseURL: String
    let path: String

    func resolve() throws -> URL {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw NetworkError.invalidURL
        }
        return url
    }
}
