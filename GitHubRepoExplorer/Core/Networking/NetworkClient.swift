//
//  NetworkClient.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation

protocol NetworkClientProtocol {
    /// Performs a request and returns only the decoded body.
    /// Use when response headers are not needed.
    func request<T: Decodable>(endpoint: some Endpoint) async throws -> T

    /// Performs a request and returns the decoded body AND the raw HTTPURLResponse.
    /// Use for paginated endpoints — read Link header via NetworkResponse.nextPageURL.
    func requestWithResponse<T: Decodable>(endpoint: some Endpoint) async throws -> NetworkResponse<T>
}

final class NetworkClient: NetworkClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
    }

    // MARK: - Decode-only

    func request<T: Decodable>(endpoint: some Endpoint) async throws -> T {
        try await requestWithResponse(endpoint: endpoint).body
    }
    
    // MARK: - With Response (headers preserved)

    func requestWithResponse<T: Decodable>(endpoint: some Endpoint) async throws -> NetworkResponse<T> {
        // Resolves to either a base+path URL or an absolute cursor URL
        let url = try endpoint.url

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method.rawValue
        endpoint.headers?.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }

        // Attach query parameters if present
        if let params = endpoint.queryParameters, !params.isEmpty {
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw NetworkError.invalidURL
            }
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
            guard let paramURL = components.url else { throw NetworkError.invalidURL }
            urlRequest.url = paramURL
        }

        // Attach body if present
        if let body = endpoint.body {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: urlRequest)
        let httpResponse = try validate(response)

        do {
            let decoded = try decoder.decode(T.self, from: data)
            return NetworkResponse(body: decoded, httpResponse: httpResponse)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    // MARK: - Private Helpers
    
    @discardableResult
    private func validate(_ response: URLResponse) throws -> HTTPURLResponse {
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch http.statusCode {
        case 200...299:
            return http
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.apiRateLimit
        case 404:
            throw NetworkError.notFound
        case 422:
            throw NetworkError.validationFailure
        case 500...599:
            throw NetworkError.serverError(http.statusCode)
        default:
            throw NetworkError.httpError(http.statusCode)
        }
    }
}
