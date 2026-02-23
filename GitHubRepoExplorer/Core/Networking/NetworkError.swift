//
//  NetworkError.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation

enum NetworkError: Error, LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case apiRateLimit
    case unauthorized
    case notFound
    case notModified
    case validationFailure
    case decodingError(Error)
    case serverError(Int)
    case httpError(Int)
    case networkError(Error)
    case noInternetConnection
    
    // MARK: - Error Description
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .apiRateLimit:
            return "Try again in a few minutes. API rate limit reached."
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .notFound:
            return "The requested resource was not found"
        case .notModified:
            return "Not modified"
        case .validationFailure:
            return "Validation failed, or the endpoint has been spammed."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noInternetConnection:
            return "No internet connection. Please check your network settings."
        }
    }
    
    // MARK: - Equatable Conformance
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidResponse, .invalidResponse),
             (.unauthorized, .unauthorized),
             (.notFound, .notFound),
             (.notModified, .notModified),
             (.validationFailure, .validationFailure),
             (.apiRateLimit, .apiRateLimit),
             (.noInternetConnection, .noInternetConnection):
            return true
        case (.serverError(let lCode), .serverError(let rCode)),
             (.httpError(let lCode), .httpError(let rCode)):
            return lCode == rCode
        case (.decodingError(let lError), .decodingError(let rError)),
             (.networkError(let lError), .networkError(let rError)):
            return lError.localizedDescription == rError.localizedDescription
        default:
            return false
        }
    }
}
