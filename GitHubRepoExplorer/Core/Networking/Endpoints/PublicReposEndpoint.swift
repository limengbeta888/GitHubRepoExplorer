//
//  PublicReposEndpoint.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation

enum PublicReposEndpoint: Endpoint {

    /// Initial or subsequent page of the public repository list.
    /// - `initial`: hits `/repositories` on the configured base URL.
    /// - `nextPage(URL)`: follows an absolute cursor URL from the `Link` header.
    case repositories(GitHubAPIConfig)
    case nextRepositories(URL)        // absolute cursor — bypasses base URL
    /// Detail for a single repository, e.g. `/repos/mojombo/god`.
    case repositoryDetail(fullName: String, config: GitHubAPIConfig)

    // MARK: Endpoint

    var url: URL {
        get throws {
            switch self {
            case .repositories(let config):
                return try PathEndpointURL(baseURL: config.baseURL, path: "/repositories").resolve()

            case .nextRepositories(let absoluteURL):
                // Cursor URLs from GitHub's Link header are already fully qualified —
                // use them as-is, no base URL composition needed.
                return absoluteURL

            case .repositoryDetail(let fullName, let config):
                return try PathEndpointURL(baseURL: config.baseURL, path: "/repos/\(fullName)").resolve()
            }
        }
    }

    var headers: [String: String]? { GitHubAPIConfig.defaultHeaders }
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
