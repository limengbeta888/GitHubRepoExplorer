//
//  MockNetworkClient.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 26/02/2026.
//

import Foundation

@MainActor
final class MockNetworkClient: NetworkClientProtocol {

    // MARK: - Configurable responses

    var detailResponses: [String: RepositoryDetail] = [:]   // key = fullName
    var repositoryListResponse: [Repository] = []

    // MARK: - Tracking

    var detailRequestCount = 0
    var listRequestCount = 0

    // MARK: - Request

    func request<T>(endpoint: some Endpoint) async throws -> T where T: Decodable {

        detailRequestCount += 1

        let url = try endpoint.url
        let path = url.path   // e.g. /repos/mojombo/god

        // Extract "mojombo/god"
        if path.contains("/repos/") {
            let fullName = path.replacingOccurrences(of: "/repos/", with: "")
            if let value = detailResponses[fullName] as? T {
                return value
            }
        }

        throw URLError(.badServerResponse)
    }

    func requestWithResponse<T>(endpoint: some Endpoint) async throws -> NetworkResponse<T> where T: Decodable {

        listRequestCount += 1

        guard let body = repositoryListResponse as? T else {
            throw URLError(.badServerResponse)
        }

        let response = HTTPURLResponse(
            url: try endpoint.url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        return NetworkResponse(body: body, httpResponse: response)
    }
}
