//
//  Endpoint.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

protocol Endpoint {
    /// The resolved URL for this endpoint.
    /// Conformers can derive this from a base URL + path,
    /// or return an absolute URL directly (e.g. pagination cursors).
    var url: URL { get throws }

    var method: HTTPMethod { get }
    var queryParameters: [String: String]? { get }
    var body: Encodable? { get }
    var headers: [String: String]? { get }
}

// MARK: - Default implementations

extension Endpoint {
    var method: HTTPMethod { .get }
    var queryParameters: [String: String]? { nil }
    var body: Encodable? { nil }
    var headers: [String: String]? { nil }
}
